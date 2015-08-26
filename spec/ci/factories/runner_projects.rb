# == Schema Information
#
# Table name: runner_projects
#
#  id         :integer          not null, primary key
#  runner_id  :integer          not null
#  project_id :integer          not null
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :runner_project do
    runner_id 1
    project_id 1
  end
end
