# frozen_string_literal: true

FactoryBot.define do
  factory :group_member, parent: :member, class: 'GroupMember' do
    access_level { GroupMember::OWNER }
    source { association(:group) }
    member_namespace_id { source.id }
    user

    trait(:created_by) do
      created_by { association(:user) }
    end

    trait(:ldap) do
      ldap { true }
    end

    trait :minimal_access do
      to_create { |instance| instance.save!(validate: false) }

      access_level { GroupMember::MINIMAL_ACCESS }
    end
  end
end
