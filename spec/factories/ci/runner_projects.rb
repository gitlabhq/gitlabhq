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

FactoryGirl.define do
  factory :ci_runner_project, class: Ci::RunnerProject do
    runner_id 1
    gl_project_id 1
  end
end
