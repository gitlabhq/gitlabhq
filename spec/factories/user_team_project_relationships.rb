# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_team_project_relationship do
    project
    user_team
    greatest_access { UsersProject::MASTER }
  end
end
