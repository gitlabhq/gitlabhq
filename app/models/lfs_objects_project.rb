# frozen_string_literal: true

class LfsObjectsProject < ApplicationRecord
  belongs_to :project
  belongs_to :lfs_object

  validates :lfs_object_id, presence: true
  validates :lfs_object_id, uniqueness: { scope: [:project_id, :repository_type], message: "already exists in repository" }
  validates :project_id, presence: true

  after_commit :update_project_statistics, on: [:create, :destroy]

  enum repository_type: {
    project: 0,
    wiki: 1,
    design: 2 ## EE-specific
  }

  private

  def update_project_statistics
    ProjectCacheWorker.perform_async(project_id, [], [:lfs_objects_size])
  end
end
