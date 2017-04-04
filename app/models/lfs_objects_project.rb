class LfsObjectsProject < ActiveRecord::Base
  belongs_to :project
  belongs_to :lfs_object

  validates :lfs_object_id, presence: true
  validates :lfs_object_id, uniqueness: { scope: [:project_id], message: "already exists in project" }
  validates :project_id, presence: true

  after_create :update_project_statistics
  after_destroy :update_project_statistics

  private

  def update_project_statistics
    ProjectCacheWorker.perform_async(project_id, [], [:lfs_objects_size])
  end
end
