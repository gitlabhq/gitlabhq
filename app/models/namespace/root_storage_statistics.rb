# frozen_string_literal: true

class Namespace::RootStorageStatistics < ApplicationRecord
  STATISTICS_ATTRIBUTES = %w(storage_size repository_size wiki_size lfs_objects_size build_artifacts_size packages_size).freeze

  self.primary_key = :namespace_id

  belongs_to :namespace
  has_one :route, through: :namespace

  scope :for_namespace_ids, ->(namespace_ids) { where(namespace_id: namespace_ids) }

  delegate :all_projects, to: :namespace

  def recalculate!
    update!(attributes_from_project_statistics)
  end

  private

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
        'COALESCE(SUM(ps.packages_size), 0) AS packages_size'
      )
  end
end
