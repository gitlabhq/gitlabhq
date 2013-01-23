# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_team_user_relationship do
    user
    user_team
    group_admin false
    permission { UsersProject::MASTER }
  end
end
