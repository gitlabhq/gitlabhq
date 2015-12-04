class LfsObject < ActiveRecord::Base
  has_many :lfs_objects_projects, dependent: :destroy
  has_many :projects, through: :lfs_objects_projects

  validates :oid, presence: true, uniqueness: true

  mount_uploader :file, LfsObjectUploader

  def storage_project(project)
    if project && project.forked?
      project.forked_from_project
    else
      project
    end
  end
end
