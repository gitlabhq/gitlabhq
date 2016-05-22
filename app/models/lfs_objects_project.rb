class LfsObjectsProject < ActiveRecord::Base
  belongs_to :project
  belongs_to :lfs_object

  validates :lfs_object_id, presence: true
  validates :lfs_object_id, uniqueness: { scope: [:project_id], message: "已经存在于项目" }
  validates :project_id, presence: true
end
