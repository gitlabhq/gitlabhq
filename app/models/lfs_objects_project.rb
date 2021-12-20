# frozen_string_literal: true

class LfsObjectsProject < ApplicationRecord
  include ::EachBatch

  belongs_to :project
  belongs_to :lfs_object

  validates :lfs_object_id, presence: true
  validates :lfs_object_id, uniqueness: { scope: [:project_id, :repository_type], message: "already exists in repository" }
  validates :project_id, presence: true

  after_commit :update_project_statistics, on: [:create, :destroy]

  enum repository_type: {
    project: 0,
    wiki: 1,
    design: 2
  }

  scope :project_id_in, ->(ids) { where(project_id: ids) }
  scope :lfs_object_in, -> (lfs_objects) { where(lfs_object: lfs_objects) }

  def self.link_to_project!(lfs_object, project)
    # We can't use an upsert here because there is no uniqueness constraint:
    # https://gitlab.com/gitlab-org/gitlab/-/issues/347466
    self.safe_find_or_create_by!(lfs_object_id: lfs_object.id, project_id: project.id) # rubocop:disable Performance/ActiveRecordSubtransactionMethods
  end

  def self.update_statistics_for_project_id(project_id)
    ProjectCacheWorker.perform_async(project_id, [], [:lfs_objects_size]) # rubocop:disable CodeReuse/Worker
  end

  private

  def update_project_statistics
    self.class.update_statistics_for_project_id(project_id)
  end
end
