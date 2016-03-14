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

FactoryGirl.define do
  factory :lfs_objects_project do
    lfs_object
    project
  end
end
