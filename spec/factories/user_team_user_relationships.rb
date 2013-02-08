# == Schema Information
#
# Table name: user_team_user_relationships
#
#  id           :integer          not null, primary key
#  user_id      :integer
#  user_team_id :integer
#  group_admin  :boolean
#  permission   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_team_user_relationship do
    user
    user_team
    group_admin false
    permission { UsersProject::MASTER }
  end
end
