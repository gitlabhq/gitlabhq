# frozen_string_literal: true

class Namespace::RootStorageStatistics < ApplicationRecord
  SNIPPETS_SIZE_STAT_NAME = 'snippets_size'
  STATISTICS_ATTRIBUTES = %W[
    storage_size
    repository_size
    wiki_size
    lfs_objects_size
    build_artifacts_size
    packages_size
    #{SNIPPETS_SIZE_STAT_NAME}
    pipeline_artifacts_size
    uploads_size
  ].freeze

  self.primary_key = :namespace_id

  belongs_to :namespace
  has_one :route, through: :namespace

  scope :for_namespace_ids, ->(namespace_ids) { where(namespace_id: namespace_ids) }

  delegate :all_projects_except_soft_deleted, to: :namespace

  enum notification_level: {
    storage_remaining: 100,
    caution: 30,
    warning: 15,
    danger: 5,
    exceeded: 0
  }, _prefix: true

  def recalculate!
    update!(merged_attributes)
  end

  def self.namespace_statistics_attributes
    %w[storage_size dependency_proxy_size]
  end

  private

  def merged_attributes
    attributes_from_project_statistics.merge!(
      attributes_from_personal_snippets,
      attributes_from_namespace_statistics,
      attributes_for_container_registry_size,
      attributes_for_forks_statistics
    ) { |_, v1, v2| v1 + v2 }
  end

  def attributes_for_container_registry_size
    container_registry_size = namespace.container_repositories_size || 0

    {
      storage_size: container_registry_size,
      container_registry_size: container_registry_size
    }.with_indifferent_access
  end

  def attributes_for_forks_statistics
    visibility_levels_to_storage_size_columns = {
      Gitlab::VisibilityLevel::PRIVATE => :private_forks_storage_size,
      Gitlab::VisibilityLevel::INTERNAL => :internal_forks_storage_size,
      Gitlab::VisibilityLevel::PUBLIC => :public_forks_storage_size
    }

    defaults = {
      private_forks_storage_size: 0,
      internal_forks_storage_size: 0,
      public_forks_storage_size: 0
    }

    defaults.merge(for_forks_statistics.transform_keys { |k| visibility_levels_to_storage_size_columns[k] })
  end

  def for_forks_statistics
    all_projects_except_soft_deleted
      .joins([:statistics, :fork_network])
      .where('fork_networks.root_project_id != projects.id')
      .group('projects.visibility_level')
      .sum('project_statistics.storage_size')
  end

  def attributes_from_project_statistics
    from_project_statistics
    .take
    .attributes
    .slice(*STATISTICS_ATTRIBUTES)
    .with_indifferent_access
  end

  def from_project_statistics
    all_projects_except_soft_deleted
      .joins('INNER JOIN project_statistics ps ON ps.project_id  = projects.id')
      .select(
        'COALESCE(SUM(ps.storage_size), 0) AS storage_size',
        'COALESCE(SUM(ps.repository_size), 0) AS repository_size',
        'COALESCE(SUM(ps.wiki_size), 0) AS wiki_size',
        'COALESCE(SUM(ps.lfs_objects_size), 0) AS lfs_objects_size',
        'COALESCE(SUM(ps.build_artifacts_size), 0) AS build_artifacts_size',
        'COALESCE(SUM(ps.packages_size), 0) AS packages_size',
        "COALESCE(SUM(ps.snippets_size), 0) AS #{SNIPPETS_SIZE_STAT_NAME}",
        'COALESCE(SUM(ps.pipeline_artifacts_size), 0) AS pipeline_artifacts_size',
        'COALESCE(SUM(ps.uploads_size), 0) AS uploads_size'
      )
  end

  def attributes_from_personal_snippets
    return {} unless namespace.user_namespace?

    from_personal_snippets
    .take
    .slice(SNIPPETS_SIZE_STAT_NAME)
    .with_indifferent_access
  end

  def from_personal_snippets
    PersonalSnippet
      .joins('INNER JOIN snippet_statistics s ON s.snippet_id = snippets.id')
      .where(author: namespace.owner_id)
      .select("COALESCE(SUM(s.repository_size), 0) AS #{SNIPPETS_SIZE_STAT_NAME}")
  end

  def from_namespace_statistics
    namespace
      .self_and_descendants
      .joins("INNER JOIN namespace_statistics ns ON ns.namespace_id  = namespaces.id")
      .select(
        'COALESCE(SUM(ns.storage_size), 0) AS storage_size',
        'COALESCE(SUM(ns.dependency_proxy_size), 0) AS dependency_proxy_size'
      )
  end

  def attributes_from_namespace_statistics
    # At the moment, only groups can have some storage data because of dependency proxy assets.
    # Therefore, if the namespace is not a group one, there is no need to perform
    # the query. If this changes in the future and we add some sort of resource to
    # users that it's store in NamespaceStatistics, we will need to remove this
    # guard clause.
    return {} unless namespace.group_namespace?

    from_namespace_statistics
    .take
    .slice(
      *self.class.namespace_statistics_attributes
    )
    .with_indifferent_access
  end
end

Namespace::RootStorageStatistics.prepend_mod_with('Namespace::RootStorageStatistics')
