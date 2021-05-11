# frozen_string_literal: true

class Namespace::RootStorageStatistics < ApplicationRecord
  SNIPPETS_SIZE_STAT_NAME = 'snippets_size'
  STATISTICS_ATTRIBUTES = %W(
    storage_size
    repository_size
    wiki_size
    lfs_objects_size
    build_artifacts_size
    packages_size
    #{SNIPPETS_SIZE_STAT_NAME}
    pipeline_artifacts_size
    uploads_size
  ).freeze

  self.primary_key = :namespace_id

  belongs_to :namespace
  has_one :route, through: :namespace

  scope :for_namespace_ids, ->(namespace_ids) { where(namespace_id: namespace_ids) }

  delegate :all_projects, to: :namespace

  def recalculate!
    update!(merged_attributes)
  end

  private

  def merged_attributes
    attributes_from_project_statistics.merge!(attributes_from_personal_snippets) { |key, v1, v2| v1 + v2 }
  end

  def attributes_from_project_statistics
    from_project_statistics
      .take
      .attributes
      .slice(*STATISTICS_ATTRIBUTES)
  end

  def from_project_statistics
    all_projects
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
    return {} unless namespace.user?

    from_personal_snippets.take.slice(SNIPPETS_SIZE_STAT_NAME)
  end

  def from_personal_snippets
    PersonalSnippet
      .joins('INNER JOIN snippet_statistics s ON s.snippet_id = snippets.id')
      .where(author: namespace.owner_id)
      .select("COALESCE(SUM(s.repository_size), 0) AS #{SNIPPETS_SIZE_STAT_NAME}")
  end
end

Namespace::RootStorageStatistics.prepend_mod_with('Namespace::RootStorageStatistics')
