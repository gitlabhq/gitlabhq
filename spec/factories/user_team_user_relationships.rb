# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_team_user_relationship do
    user_id 1
    user_team_id 1
    group_admin false
    permission 1
  end
end
