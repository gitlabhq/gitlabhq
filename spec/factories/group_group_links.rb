# frozen_string_literal: true

FactoryBot.define do
  factory :group_group_link do
    shared_group { create(:group) }
    shared_with_group { create(:group) }
    group_access { GroupMember::DEVELOPER }
  end
end
