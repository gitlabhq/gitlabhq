class LfsObject < ActiveRecord::Base
  # EE specific modules
  prepend EE::LfsObject

  has_many :lfs_objects_projects, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :projects, through: :lfs_objects_projects

  validates :oid, presence: true, uniqueness: true

  scope :with_files_stored_locally, ->() { where(file_store: [nil, LfsObjectUploader::LOCAL_STORE]) }

  mount_uploader :file, LfsObjectUploader

  def storage_project(project)
    if project && project.forked?
      storage_project(project.forked_from_project)
    else
      project
    end
  end

  def project_allowed_access?(project)
    projects.exists?(storage_project(project).id)
  end

  def self.destroy_unreferenced
    joins("LEFT JOIN lfs_objects_projects ON lfs_objects_projects.lfs_object_id = #{table_name}.id")
        .where(lfs_objects_projects: { id: nil })
        .destroy_all
  end
end
