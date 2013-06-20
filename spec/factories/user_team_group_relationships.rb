# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_team_group_relationship do
    user_team
    group
    greatest_access 40
  end
end
