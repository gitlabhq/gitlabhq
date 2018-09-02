FactoryBot.define do
  factory :group_group_link do
    shared_group { group }
    shared_with_group { group }
    access_level { GroupMember::DEVELOPER }
    expires_at nil
  end
end
