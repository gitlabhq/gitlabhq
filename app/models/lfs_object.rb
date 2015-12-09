# == Schema Information
#
# Table name: lfs_objects
#
#  id         :integer          not null, primary key
#  oid        :string(255)      not null
#  size       :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  file       :string(255)
#

class LfsObject < ActiveRecord::Base
  has_many :lfs_objects_projects, dependent: :destroy
  has_many :projects, through: :lfs_objects_projects

  validates :oid, presence: true, uniqueness: true

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
end
