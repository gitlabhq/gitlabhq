# == Schema Information
#
# Table name: user_team_project_relationships
#
#  id              :integer          not null, primary key
#  project_id      :integer
#  user_team_id    :integer
#  greatest_access :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_team_project_relationship do
    project
    user_team
    greatest_access { UsersProject::MASTER }
  end
end
