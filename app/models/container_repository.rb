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

  MAX_TAGS_PAGES = 2000
  MAX_DELETION_FAILURES = 10

  # The Registry client uses JWT token to authenticate to Registry. We cache the client using expiration
  # time of JWT token. However it's possible that the token is valid but by the time the request is made to
  # Regsitry, it's already expired. To prevent this case, we are subtracting a few seconds, defined by this constant
  # from the cache expiration time.
  AUTH_TOKEN_USAGE_RESERVED_TIME_IN_SECS = 5

  belongs_to :project

  validates :name, length: { minimum: 0, allow_nil: false }
  validates :name, uniqueness: { scope: :project_id }
  validates :failed_deletion_count, presence: true
  validates :failed_deletion_count, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_DELETION_FAILURES }

  enum status: { delete_scheduled: 0, delete_failed: 1, delete_ongoing: 2 }
  enum expiration_policy_cleanup_status: { cleanup_unscheduled: 0, cleanup_scheduled: 1, cleanup_unfinished: 2, cleanup_ongoing: 3 }

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
  scope :with_stale_ongoing_cleanup, ->(threshold) { cleanup_ongoing.expiration_policy_started_at_nil_or_before(threshold) }
  scope :with_stale_delete_at, ->(threshold) { where('delete_started_at < ?', threshold) }

  before_update :set_status_updated_at_to_now, if: :status_changed?

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

  def self.registry_client_expiration_time
    (Gitlab::CurrentSettings.container_registry_token_expire_delay * 60) - AUTH_TOKEN_USAGE_RESERVED_TIME_IN_SECS
  end

  # needed by Packages::Destructible
  def self.pending_destruction
    delete_scheduled.where('next_delete_attempt_at IS NULL OR next_delete_attempt_at < ?', Time.zone.now)
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

  # If the container registry GitLab API is available, the API
  # does a search of tags containing the name and we filter them
  # to find the exact match. Otherwise, we instantiate a tag.
  def tag(tag)
    if gitlab_api_client.supports_gitlab_api?
      page = tags_page(name: tag)
      return if page[:tags].blank?

      page[:tags].find { |result_tag| result_tag.name == tag }
    else
      ContainerRegistry::Tag.new(self, tag)
    end
  end

  def image_manifest(reference)
    client.repository_manifest(path, reference)
  end

  def manifest
    @manifest ||= client.repository_tags(path)
  end

  def tags
    strong_memoize(:tags) do
      if gitlab_api_client.supports_gitlab_api?
        result = []
        each_tags_page do |array_of_tags|
          result << array_of_tags
        end

        result.flatten
      else
        next [] unless manifest && manifest['tags']

        manifest['tags'].sort.map do |tag|
          ContainerRegistry::Tag.new(self, tag)
        end
      end
    end
  end

  def each_tags_page(page_size: 100, &block)
    raise ArgumentError, _('GitLab container registry API not supported') unless gitlab_api_client.supports_gitlab_api?
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

  def tags_page(before: nil, last: nil, sort: nil, name: nil, page_size: 100, referrers: nil, referrer_type: nil)
    raise ArgumentError, _('GitLab container registry API not supported') unless gitlab_api_client.supports_gitlab_api?

    page = gitlab_api_client.tags(
      self.path,
      page_size: page_size,
      before: before,
      last: last,
      sort: sort,
      name: name,
      referrers: referrers,
      referrer_type: referrer_type
    )

    {
      tags: transform_tags_page(page[:response_body]),
      pagination: page[:pagination]
    }
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

    digests.map { |digest| delete_tag(digest) }.all?
  end

  def delete_tag(name_or_digest)
    client.delete_repository_tag_by_digest(self.path, name_or_digest)
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
      next unless gitlab_api_client.supports_gitlab_api?

      gitlab_api_client_repository_details['size_bytes']
    end
  end

  def last_published_at
    return unless gitlab_api_client.supports_gitlab_api?

    timestamp_string = gitlab_api_client_repository_details['last_published_at']
    DateTime.iso8601(timestamp_string)
  rescue ArgumentError
    nil
  end
  strong_memoize_attr :last_published_at

  def set_delete_ongoing_status
    now = Time.zone.now

    update_columns(
      status: :delete_ongoing,
      delete_started_at: now,
      status_updated_at: now,
      next_delete_attempt_at: nil
    )
  end

  def set_delete_scheduled_status
    update_columns(
      status: :delete_scheduled,
      delete_started_at: nil,
      status_updated_at: Time.zone.now,
      failed_deletion_count: failed_deletion_count + 1,
      next_delete_attempt_at: next_delete_attempt_with_delay
    )
  end

  def set_delete_failed_status
    update_columns(
      status: :delete_failed,
      delete_started_at: nil,
      status_updated_at: Time.zone.now
    )
  end

  def self.build_from_path(path)
    self.new(project: path.repository_project, name: path.repository_name)
  end

  def self.find_or_create_from_path!(path)
    ContainerRepository.upsert({
      project_id: path.repository_project.id,
      name: path.repository_name
    }, unique_by: %i[project_id name])

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

  def transform_tags_page(tags_response_body)
    return [] unless tags_response_body

    tags_response_body.map do |raw_tag|
      tag = ContainerRegistry::Tag.new(self, raw_tag['name'], from_api: true)
      tag.force_created_at_from_iso8601(raw_tag['created_at'])
      tag.updated_at = raw_tag['updated_at']
      tag.total_size = raw_tag['size_bytes']
      tag.manifest_digest = raw_tag['digest']
      tag.revision = raw_tag['config_digest'].to_s.split(':')[1] || ''
      tag.referrers = raw_tag['referrers']
      tag.published_at = raw_tag['published_at']
      tag.media_type = raw_tag['media_type']
      tag
    end
  end

  def set_status_updated_at_to_now
    self.status_updated_at = Time.zone.now
  end

  def gitlab_api_client_repository_details
    gitlab_api_client.repository_details(self.path, sizing: :self)
  end
  strong_memoize_attr :gitlab_api_client_repository_details

  def next_delete_attempt_with_delay(now = Time.zone.now)
    now + (2**failed_deletion_count).minutes
  end
end

ContainerRepository.prepend_mod_with('ContainerRepository')
