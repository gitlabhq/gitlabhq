# == Schema Information
#
# Table name: users_groups
#
#  id           :integer          not null, primary key
#  group_access :integer          not null
#  group_id     :integer          not null
#  user_id      :integer          not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

FactoryGirl.define do
  factory :users_group do
    group_access { UsersGroup::OWNER }
    group
    user
  end
end
