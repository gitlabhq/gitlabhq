# frozen_string_literal: true

class ContainerRepository < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include Gitlab::SQL::Pattern
  include EachBatch
  include Sortable
  include AfterCommitQueue
  include Packages::Destructible

  WAITING_CLEANUP_STATUSES = %i[cleanup_scheduled cleanup_unfinished].freeze
  REQUIRING_CLEANUP_STATUSES = %i[cleanup_unscheduled cleanup_scheduled].freeze

  IDLE_MIGRATION_STATES = %w[default pre_import_done import_done import_aborted import_skipped].freeze
  ACTIVE_MIGRATION_STATES = %w[pre_importing importing].freeze
  MIGRATION_STATES = (IDLE_MIGRATION_STATES + ACTIVE_MIGRATION_STATES).freeze
  ABORTABLE_MIGRATION_STATES = (ACTIVE_MIGRATION_STATES + %w[pre_import_done default]).freeze
  SKIPPABLE_MIGRATION_STATES = (ABORTABLE_MIGRATION_STATES + %w[import_aborted]).freeze

  MIGRATION_PHASE_1_STARTED_AT = Date.new(2021, 11, 4).freeze
  MIGRATION_PHASE_1_ENDED_AT = Date.new(2022, 01, 23).freeze

  MAX_TAGS_PAGES = 2000

  # The Registry client uses JWT token to authenticate to Registry. We cache the client using expiration
  # time of JWT token. However it's possible that the token is valid but by the time the request is made to
  # Regsitry, it's already expired. To prevent this case, we are subtracting a few seconds, defined by this constant
  # from the cache expiration time.
  AUTH_TOKEN_USAGE_RESERVED_TIME_IN_SECS = 5

  TooManyImportsError = Class.new(StandardError)

  belongs_to :project

  validates :name, length: { minimum: 0, allow_nil: false }
  validates :name, uniqueness: { scope: :project_id }
  validates :migration_state, presence: true, inclusion: { in: MIGRATION_STATES }
  validates :migration_aborted_in_state, inclusion: { in: ABORTABLE_MIGRATION_STATES }, allow_nil: true

  validates :migration_retries_count, presence: true,
    numericality: { greater_than_or_equal_to: 0 },
    allow_nil: false

  enum status: { delete_scheduled: 0, delete_failed: 1, delete_ongoing: 2 }
  enum expiration_policy_cleanup_status: { cleanup_unscheduled: 0, cleanup_scheduled: 1, cleanup_unfinished: 2, cleanup_ongoing: 3 }

  enum migration_skipped_reason: {
    not_in_plan: 0,
    too_many_retries: 1,
    too_many_tags: 2,
    root_namespace_in_deny_list: 3,
    migration_canceled: 4,
    not_found: 5,
    native_import: 6,
    migration_forced_canceled: 7,
    migration_canceled_by_registry: 8
  }

  delegate :client, :gitlab_api_client, to: :registry

  scope :ordered, -> { order(:name) }
  scope :with_api_entity_associations, -> { preload(project: [:route, { namespace: :route }]) }
  scope :for_group_and_its_subgroups, ->(group) do
    project_scope = Project
      .for_group_and_its_subgroups(group)
      .with_feature_enabled(:container_registry)
      .select(:id)

    joins("INNER JOIN (#{project_scope.to_sql}) projects on projects.id=container_repositories.project_id")
  end
  scope :for_project_id, ->(project_id) { where(project_id: project_id) }
  scope :search_by_name, ->(query) { fuzzy_search(query, [:name], use_minimum_char_limit: false) }
  scope :waiting_for_cleanup, -> { where(expiration_policy_cleanup_status: WAITING_CLEANUP_STATUSES) }
  scope :expiration_policy_started_at_nil_or_before, ->(timestamp) { where('expiration_policy_started_at < ? OR expiration_policy_started_at IS NULL', timestamp) }
  scope :with_migration_import_started_at_nil_or_before, ->(timestamp) { where("COALESCE(migration_import_started_at, '01-01-1970') < ?", timestamp) }
  scope :with_migration_pre_import_started_at_nil_or_before, ->(timestamp) { where("COALESCE(migration_pre_import_started_at, '01-01-1970') < ?", timestamp) }
  scope :with_migration_pre_import_done_at_nil_or_before, ->(timestamp) { where("COALESCE(migration_pre_import_done_at, '01-01-1970') < ?", timestamp) }
  scope :with_stale_ongoing_cleanup, ->(threshold) { cleanup_ongoing.expiration_policy_started_at_nil_or_before(threshold) }
  scope :with_stale_delete_at, ->(threshold) { where('delete_started_at < ?', threshold) }
  scope :import_in_process, -> { where(migration_state: %w[pre_importing pre_import_done importing]) }

  scope :recently_done_migration_step, -> do
    where(migration_state: %w[import_done pre_import_done import_aborted import_skipped])
      .order(Arel.sql('GREATEST(migration_pre_import_done_at, migration_import_done_at, migration_aborted_at, migration_skipped_at) DESC'))
  end

  scope :ready_for_import, -> do
    # There is no yaml file for the container_registry_phase_2_deny_list
    # feature flag since it is only accessed in this query.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/350543 tracks the rollout and
    # removal of this feature flag.
    joins(project: [:namespace]).where(
      migration_state: [:default],
      created_at: ...ContainerRegistry::Migration.created_before
    ).with_target_import_tier
    .where(
      "NOT EXISTS (
        SELECT 1
        FROM feature_gates
        WHERE feature_gates.feature_key = 'container_registry_phase_2_deny_list'
        AND feature_gates.key = 'actors'
        AND feature_gates.value = concat('Group:', namespaces.traversal_ids[1])
      )"
    )
  end

  before_update :set_status_updated_at_to_now, if: :status_changed?

  state_machine :migration_state, initial: :default, use_transactions: false do
    state :pre_importing do
      validates :migration_pre_import_started_at, presence: true
      validates :migration_pre_import_done_at, presence: false
    end

    state :pre_import_done do
      validates :migration_pre_import_done_at, presence: true
    end

    state :importing do
      validates :migration_import_started_at, presence: true
      validates :migration_import_done_at, presence: false
    end

    state :import_done

    state :import_skipped do
      validates :migration_skipped_reason, :migration_skipped_at, presence: true
    end

    state :import_aborted do
      validates :migration_aborted_at, presence: true
      validates :migration_retries_count, presence: true, numericality: { greater_than_or_equal_to: 1 }
    end

    event :start_pre_import do
      transition %i[default pre_importing importing import_aborted] => :pre_importing
    end

    event :finish_pre_import do
      transition %i[pre_importing importing import_aborted] => :pre_import_done
    end

    event :start_import do
      transition %i[pre_import_done pre_importing importing import_aborted] => :importing
    end

    event :finish_import do
      transition %i[default pre_importing importing import_aborted] => :import_done
    end

    event :already_migrated do
      transition default: :import_done
    end

    event :abort_import do
      transition ABORTABLE_MIGRATION_STATES.map(&:to_sym) => :import_aborted
    end

    event :skip_import do
      transition SKIPPABLE_MIGRATION_STATES.map(&:to_sym) => :import_skipped
    end

    event :retry_pre_import do
      transition %i[pre_importing importing import_aborted] => :pre_importing
    end

    event :retry_import do
      transition %i[pre_importing importing import_aborted] => :importing
    end

    before_transition any => :pre_importing do |container_repository|
      container_repository.migration_pre_import_started_at = Time.zone.now
      container_repository.migration_pre_import_done_at = nil
    end

    after_transition any => :pre_importing do |container_repository, transition|
      forced = transition.args.first.try(:[], :forced)
      next if forced

      container_repository.try_import do
        container_repository.migration_pre_import
      end
    end

    before_transition any => :pre_import_done do |container_repository|
      container_repository.migration_pre_import_done_at = Time.zone.now
    end

    before_transition any => :importing do |container_repository|
      container_repository.migration_import_started_at = Time.zone.now
      container_repository.migration_import_done_at = nil
    end

    after_transition any => :importing do |container_repository, transition|
      forced = transition.args.first.try(:[], :forced)
      next if forced

      container_repository.try_import do
        container_repository.migration_import
      end
    end

    before_transition any => :import_done do |container_repository|
      container_repository.migration_import_done_at = Time.zone.now
    end

    before_transition any => :import_aborted do |container_repository|
      container_repository.migration_aborted_in_state = container_repository.migration_state
      container_repository.migration_aborted_at = Time.zone.now
      container_repository.migration_retries_count += 1
    end

    after_transition any => :import_aborted do |container_repository|
      if container_repository.retried_too_many_times?
        container_repository.skip_import(reason: :too_many_retries)
      end
    end

    before_transition import_aborted: any do |container_repository|
      container_repository.migration_aborted_at = nil
      container_repository.migration_aborted_in_state = nil
    end

    before_transition any => :import_skipped do |container_repository|
      container_repository.migration_skipped_at = Time.zone.now
    end

    before_transition any => %i[import_done import_aborted import_skipped] do |container_repository|
      container_repository.run_after_commit do
        ::ContainerRegistry::Migration::EnqueuerWorker.enqueue_a_job
      end
    end
  end

  # Container Repository model and the code that makes API calls
  # are tied. Sometimes (mainly in Geo) we need to work with Registry
  # when Container Repository record doesn't even exist.
  # The ability to create a not-persisted record with a certain "path" parameter
  # is very useful
  attr_writer :path

  def self.exists_by_path?(path)
    where(
      project: path.repository_project,
      name: path.repository_name
    ).exists?
  end

  def self.all_migrated?
    # check that the set of non migrated repositories is empty
    where(created_at: ...MIGRATION_PHASE_1_ENDED_AT)
      .where.not(migration_state: 'import_done')
      .empty?
  end

  def self.with_enabled_policy
    joins('INNER JOIN container_expiration_policies ON container_repositories.project_id = container_expiration_policies.project_id')
      .where(container_expiration_policies: { enabled: true })
  end

  def self.requiring_cleanup
    with_enabled_policy
      .where(container_repositories: { expiration_policy_cleanup_status: REQUIRING_CLEANUP_STATUSES })
      .where('container_repositories.expiration_policy_started_at IS NULL OR container_repositories.expiration_policy_started_at < container_expiration_policies.next_run_at')
      .where('container_expiration_policies.next_run_at < ?', Time.zone.now)
  end

  def self.with_unfinished_cleanup
    with_enabled_policy.cleanup_unfinished
  end

  def self.with_stale_migration(before_timestamp)
    stale_pre_importing = with_migration_states(:pre_importing)
                            .with_migration_pre_import_started_at_nil_or_before(before_timestamp)
    stale_pre_import_done = with_migration_states(:pre_import_done)
                              .with_migration_pre_import_done_at_nil_or_before(before_timestamp)
    stale_importing = with_migration_states(:importing)
                        .with_migration_import_started_at_nil_or_before(before_timestamp)

    union = ::Gitlab::SQL::Union.new([
                                       stale_pre_importing,
                                       stale_pre_import_done,
                                       stale_importing
                                     ])
    from("(#{union.to_sql}) #{ContainerRepository.table_name}")
  end

  def self.with_target_import_tier
    # overridden in ee
    #
    # Repositories are being migrated by tier on Saas, so we need to
    # filter by plan/subscription which is not available in FOSS
    all
  end

  def self.registry_client_expiration_time
    (Gitlab::CurrentSettings.container_registry_token_expire_delay * 60) - AUTH_TOKEN_USAGE_RESERVED_TIME_IN_SECS
  end

  class << self
    alias_method :pending_destruction, :delete_scheduled # needed by Packages::Destructible
  end

  def skip_import(reason:)
    self.migration_skipped_reason = reason

    super
  end

  def start_pre_import(*args)
    return false unless ContainerRegistry::Migration.enabled?

    super(*args)
  end

  def retry_pre_import
    return false unless ContainerRegistry::Migration.enabled?

    super
  end

  def retry_import
    return false unless ContainerRegistry::Migration.enabled?

    super
  end

  def finish_pre_import_and_start_import
    # nothing to do between those two transitions for now.
    finish_pre_import && start_import
  end

  def retry_aborted_migration
    return unless migration_state == 'import_aborted'

    reconcile_import_status(external_import_status) do
      # If the import_status request fails, use the timestamp to guess current state
      migration_pre_import_done_at ? retry_import : retry_pre_import
    end
  end

  def reconcile_import_status(status)
    case status
    when 'native'
      finish_import_as(:native_import)
    when 'pre_import_in_progress'
      return if pre_importing?

      start_pre_import(forced: true)
    when 'import_in_progress'
      return if importing?

      start_import(forced: true)
    when 'import_complete'
      finish_import
    when 'import_failed', 'import_canceled'
      retry_import
    when 'pre_import_complete'
      finish_pre_import_and_start_import
    when 'pre_import_failed', 'pre_import_canceled'
      retry_pre_import
    else
      yield
    end
  end

  def try_import
    raise ArgumentError, 'block not given' unless block_given?

    try_count = 0
    begin
      try_count += 1

      case yield
      when :ok
        return true
      when :not_found
        finish_import_as(:not_found)
      when :already_imported
        finish_import_as(:native_import)
      else
        abort_import
      end

      false
    rescue TooManyImportsError
      if try_count <= ::ContainerRegistry::Migration.start_max_retries
        sleep 0.1 * try_count
        retry
      else
        abort_import
        false
      end
    end
  end

  def retried_too_many_times?
    migration_retries_count >= ContainerRegistry::Migration.max_retries
  end

  def nearing_or_exceeded_retry_limit?
    migration_retries_count >= ContainerRegistry::Migration.max_retries - 1
  end

  def migrated?
    Gitlab.com?
  end

  def last_import_step_done_at
    [migration_pre_import_done_at, migration_import_done_at, migration_aborted_at, migration_skipped_at].compact.max
  end

  def external_import_status
    strong_memoize(:import_status) do
      gitlab_api_client.import_status(self.path)
    end
  end

  # rubocop: disable CodeReuse/ServiceClass
  def registry
    strong_memoize_with_expiration(:registry, self.class.registry_client_expiration_time) do
      token = Auth::ContainerRegistryAuthenticationService.full_access_token(path)

      url = Gitlab.config.registry.api_url
      host_port = Gitlab.config.registry.host_port

      ContainerRegistry::Registry.new(url, token: token, path: host_port)
    end
  end
  # rubocop: enable CodeReuse/ServiceClass

  def path
    @path ||= [project.full_path, name]
      .select(&:present?).join('/').downcase
  end

  def location
    File.join(registry.path, path)
  end

  def tag(tag)
    ContainerRegistry::Tag.new(self, tag)
  end

  def manifest
    @manifest ||= client.repository_tags(path)
  end

  def tags
    return [] unless manifest && manifest['tags']

    strong_memoize(:tags) do
      manifest['tags'].sort.map do |tag|
        ContainerRegistry::Tag.new(self, tag)
      end
    end
  end

  def each_tags_page(page_size: 100, &block)
    raise ArgumentError, 'not a migrated repository' unless migrated?
    raise ArgumentError, 'block not given' unless block

    # dummy uri to initialize the loop
    next_page_uri = URI('')
    page_count = 0

    while next_page_uri && page_count < MAX_TAGS_PAGES
      last = Rack::Utils.parse_nested_query(next_page_uri.query)['last']
      current_page = gitlab_api_client.tags(self.path, page_size: page_size, last: last)

      if current_page&.key?(:response_body)
        yield transform_tags_page(current_page[:response_body])
        next_page_uri = current_page.dig(:pagination, :next, :uri)
      else
        # no current page. Break the loop
        next_page_uri = nil
      end

      page_count += 1
    end

    raise 'too many pages requested' if page_count >= MAX_TAGS_PAGES
  end

  def tags_count
    return 0 unless manifest && manifest['tags']

    manifest['tags'].size
  end

  def blob(config)
    ContainerRegistry::Blob.new(self, config)
  end

  def has_tags?
    tags.any?
  end

  def root_repository?
    name.empty?
  end

  def delete_tags!
    return unless has_tags?

    digests = tags.map { |tag| tag.digest }.compact.to_set

    digests.map { |digest| delete_tag_by_digest(digest) }.all?
  end

  def delete_tag_by_digest(digest)
    client.delete_repository_tag_by_digest(self.path, digest)
  end

  def delete_tag_by_name(name)
    client.delete_repository_tag_by_name(self.path, name)
  end

  def start_expiration_policy!
    update!(
      expiration_policy_started_at: Time.zone.now,
      last_cleanup_deleted_tags_count: nil,
      expiration_policy_cleanup_status: :cleanup_ongoing
    )
  end

  def size
    strong_memoize(:size) do
      next unless Gitlab.com?
      next if self.created_at.before?(MIGRATION_PHASE_1_STARTED_AT) && self.migration_state != 'import_done'
      next unless gitlab_api_client.supports_gitlab_api?

      gitlab_api_client.repository_details(self.path, sizing: :self)['size_bytes']
    end
  end

  def set_delete_ongoing_status
    now = Time.zone.now
    update_columns(
      status: :delete_ongoing,
      delete_started_at: now,
      status_updated_at: now
    )
  end

  def set_delete_scheduled_status
    update_columns(
      status: :delete_scheduled,
      delete_started_at: nil,
      status_updated_at: Time.zone.now
    )
  end

  def migration_in_active_state?
    migration_state.in?(ACTIVE_MIGRATION_STATES)
  end

  def migration_importing?
    migration_state == 'importing'
  end

  def migration_pre_importing?
    migration_state == 'pre_importing'
  end

  def migration_pre_import
    return :error unless gitlab_api_client.supports_gitlab_api?

    response = gitlab_api_client.pre_import_repository(self.path)
    raise TooManyImportsError if response == :too_many_imports

    response
  end

  def migration_import
    return :error unless gitlab_api_client.supports_gitlab_api?

    response = gitlab_api_client.import_repository(self.path)
    raise TooManyImportsError if response == :too_many_imports

    response
  end

  def migration_cancel
    return :error unless gitlab_api_client.supports_gitlab_api?

    gitlab_api_client.cancel_repository_import(self.path)
  end

  # This method is not meant for consumption by the code
  # It is meant for manual use in the case that a migration needs to be
  # cancelled by an admin or SRE
  def force_migration_cancel
    return :error unless gitlab_api_client.supports_gitlab_api?

    response = gitlab_api_client.cancel_repository_import(self.path, force: true)

    skip_import(reason: :migration_forced_canceled) if response[:status] == :ok

    response
  end

  def self.build_from_path(path)
    self.new(project: path.repository_project, name: path.repository_name)
  end

  def self.find_or_create_from_path(path)
    repository = safe_find_or_create_by(
      project: path.repository_project,
      name: path.repository_name
    )
    return repository if repository.persisted?

    find_by_path!(path)
  end

  def self.build_root_repository(project)
    self.new(project: project, name: '')
  end

  def self.find_by_path!(path)
    self.find_by!(project: path.repository_project, name: path.repository_name)
  end

  def self.find_by_path(path)
    self.find_by(project: path.repository_project, name: path.repository_name)
  end

  private

  def finish_import_as(reason)
    self.migration_skipped_reason = reason
    finish_import
  end

  def transform_tags_page(tags_response_body)
    return [] unless tags_response_body

    tags_response_body.map do |raw_tag|
      tag = ContainerRegistry::Tag.new(self, raw_tag['name'])
      tag.force_created_at_from_iso8601(raw_tag['created_at'])
      tag.updated_at = raw_tag['updated_at']
      tag
    end
  end

  def set_status_updated_at_to_now
    self.status_updated_at = Time.zone.now
  end
end

ContainerRepository.prepend_mod_with('ContainerRepository')
