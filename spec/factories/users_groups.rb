FactoryGirl.define do
  factory :users_group do
    group_access { UsersGroup::OWNER }
    group
    user
  end
end
