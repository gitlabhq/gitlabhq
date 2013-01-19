# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_team_project_relationship do
    project_id 1
    user_team_id 1
    greatest_access 1
  end
end
