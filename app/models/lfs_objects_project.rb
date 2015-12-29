# == Schema Information
#
# Table name: lfs_objects_projects
#
#  id            :integer          not null, primary key
#  lfs_object_id :integer          not null
#  project_id    :integer          not null
#  created_at    :datetime
#  updated_at    :datetime
#

class LfsObjectsProject < ActiveRecord::Base
  belongs_to :project
  belongs_to :lfs_object

  validates :lfs_object_id, presence: true
  validates :lfs_object_id, uniqueness: { scope: [:project_id], message: "already exists in project" }
  validates :project_id, presence: true
end
