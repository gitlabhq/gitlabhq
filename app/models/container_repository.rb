# frozen_string_literal: true

class ContainerRepository < ApplicationRecord
  include Gitlab::Utils::StrongMemoize
  include Gitlab::SQL::Pattern
  include EachBatch
  include Sortable

  WAITING_CLEANUP_STATUSES = %i[cleanup_scheduled cleanup_unfinished].freeze
  REQUIRING_CLEANUP_STATUSES = %i[cleanup_unscheduled cleanup_scheduled].freeze

  belongs_to :project

  validates :name, length: { minimum: 0, allow_nil: false }
  validates :name, uniqueness: { scope: :project_id }

  enum status: { delete_scheduled: 0, delete_failed: 1 }
  enum expiration_policy_cleanup_status: { cleanup_unscheduled: 0, cleanup_scheduled: 1, cleanup_unfinished: 2, cleanup_ongoing: 3 }

  delegate :client, to: :registry

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
  scope :with_stale_ongoing_cleanup, ->(threshold) { cleanup_ongoing.where('expiration_policy_started_at < ?', threshold) }

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

  def self.build_from_path(path)
    self.new(project: path.repository_project,
             name: path.repository_name)
  end

  def self.create_from_path!(path)
    safe_find_or_create_by!(project: path.repository_project,
                                 name: path.repository_name)
  end

  def self.build_root_repository(project)
    self.new(project: project, name: '')
  end

  def self.find_by_path!(path)
    self.find_by!(project: path.repository_project,
                  name: path.repository_name)
  end
end

ContainerRepository.prepend_mod_with('ContainerRepository')
