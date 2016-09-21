FactoryGirl.define do
  factory :group_member do
    access_level { GroupMember::OWNER }
    group
    user
  end
end
