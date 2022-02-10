# frozen_string_literal: true

class ContainerRepository < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include Gitlab::SQL::Pattern
  include EachBatch
  include Sortable

  WAITING_CLEANUP_STATUSES = %i[cleanup_scheduled cleanup_unfinished].freeze
  REQUIRING_CLEANUP_STATUSES = %i[cleanup_unscheduled cleanup_scheduled].freeze
  IDLE_MIGRATION_STATES = %w[default pre_import_done import_done import_aborted import_skipped].freeze
  ACTIVE_MIGRATION_STATES = %w[pre_importing importing].freeze
  ABORTABLE_MIGRATION_STATES = (ACTIVE_MIGRATION_STATES + ['pre_import_done']).freeze
  MIGRATION_STATES = (IDLE_MIGRATION_STATES + ACTIVE_MIGRATION_STATES).freeze

  belongs_to :project

  validates :name, length: { minimum: 0, allow_nil: false }
  validates :name, uniqueness: { scope: :project_id }
  validates :migration_state, presence: true, inclusion: { in: MIGRATION_STATES }
  validates :migration_aborted_in_state, inclusion: { in: ABORTABLE_MIGRATION_STATES }, allow_nil: true

  validates :migration_retries_count, presence: true,
                                      numericality: { greater_than_or_equal_to: 0 },
                                      allow_nil: false

  enum status: { delete_scheduled: 0, delete_failed: 1 }
  enum expiration_policy_cleanup_status: { cleanup_unscheduled: 0, cleanup_scheduled: 1, cleanup_unfinished: 2, cleanup_ongoing: 3 }
  enum migration_skipped_reason: { not_in_plan: 0, too_many_retries: 1, too_many_tags: 2, root_namespace_in_deny_list: 3 }

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
  scope :with_stale_ongoing_cleanup, ->(threshold) { cleanup_ongoing.where('expiration_policy_started_at < ?', threshold) }

  state_machine :migration_state, initial: :default do
    state :pre_importing do
      validates :migration_pre_import_started_at, presence: true
      validates :migration_pre_import_done_at, presence: false
    end

    state :pre_import_done do
      validates :migration_pre_import_started_at,
                :migration_pre_import_done_at,
                presence: true
    end

    state :importing do
      validates :migration_import_started_at, presence: true
      validates :migration_import_done_at, presence: false
    end

    state :import_done

    state :import_skipped do
      validates :migration_skipped_reason,
                :migration_skipped_at,
                presence: true
    end

    state :import_aborted do
      validates :migration_aborted_at, presence: true
      validates :migration_retries_count, presence: true, numericality: { greater_than_or_equal_to: 1 }
    end

    event :start_pre_import do
      transition default: :pre_importing
    end

    event :finish_pre_import do
      transition pre_importing: :pre_import_done
    end

    event :start_import do
      transition pre_import_done: :importing
    end

    event :finish_import do
      transition importing: :import_done
    end

    event :already_migrated do
      transition default: :import_done
    end

    event :abort_import do
      transition ABORTABLE_MIGRATION_STATES.map(&:to_sym) => :import_aborted
    end

    event :skip_import do
      transition %i[default pre_importing importing] => :import_skipped
    end

    event :retry_pre_import do
      transition import_aborted: :pre_importing
    end

    event :retry_import do
      transition import_aborted: :importing
    end

    before_transition any => :pre_importing do |container_repository|
      container_repository.migration_pre_import_started_at = Time.zone.now
      container_repository.migration_pre_import_done_at = nil
    end

    after_transition any => :pre_importing do |container_repository|
      container_repository.abort_import unless container_repository.migration_pre_import == :ok
    end

    before_transition pre_importing: :pre_import_done do |container_repository|
      container_repository.migration_pre_import_done_at = Time.zone.now
    end

    before_transition any => :importing do |container_repository|
      container_repository.migration_import_started_at = Time.zone.now
      container_repository.migration_import_done_at = nil
    end

    after_transition any => :importing do |container_repository|
      container_repository.abort_import unless container_repository.migration_import == :ok
    end

    before_transition importing: :import_done do |container_repository|
      container_repository.migration_import_done_at = Time.zone.now
    end

    before_transition any => :import_aborted do |container_repository|
      container_repository.migration_aborted_in_state = container_repository.migration_state
      container_repository.migration_aborted_at = Time.zone.now
      container_repository.migration_retries_count += 1
    end

    before_transition import_aborted: any do |container_repository|
      container_repository.migration_aborted_at = nil
      container_repository.migration_aborted_in_state = nil
    end

    before_transition any => :import_skipped do |container_repository|
      container_repository.migration_skipped_at = Time.zone.now
    end

    before_transition any => %i[import_done import_aborted] do
      # EnqueuerJob.enqueue perform_async or perform_in depending on the speed FF
      # To be implemented in https://gitlab.com/gitlab-org/gitlab/-/issues/349744
    end
  end

  def self.exists_by_path?(path)
    where(
      project: path.repository_project,
      name: path.repository_name
    ).exists?
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

  def skip_import(reason:)
    self.migration_skipped_reason = reason

    super
  end

  def start_pre_import
    return false unless ContainerRegistry::Migration.enabled?

    super
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

  # rubocop: disable CodeReuse/ServiceClass
  def registry
    @registry ||= begin
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

    digests.map(&method(:delete_tag_by_digest)).all?
  end

  def delete_tag_by_digest(digest)
    client.delete_repository_tag_by_digest(self.path, digest)
  end

  def delete_tag_by_name(name)
    client.delete_repository_tag_by_name(self.path, name)
  end

  def reset_expiration_policy_started_at!
    update!(expiration_policy_started_at: nil)
  end

  def start_expiration_policy!
    update!(expiration_policy_started_at: Time.zone.now)
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

    gitlab_api_client.pre_import_repository(self.path)
  end

  def migration_import
    return :error unless gitlab_api_client.supports_gitlab_api?

    gitlab_api_client.import_repository(self.path)
  end

  def self.build_from_path(path)
    self.new(project: path.repository_project,
             name: path.repository_name)
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
    self.find_by!(project: path.repository_project,
                  name: path.repository_name)
  end

  def self.find_by_path(path)
    self.find_by(project: path.repository_project,
                  name: path.repository_name)
  end
end

ContainerRepository.prepend_mod_with('ContainerRepository')
