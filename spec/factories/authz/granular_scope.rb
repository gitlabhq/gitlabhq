# frozen_string_literal: true

FactoryBot.define do
  factory :granular_scope, class: 'Authz::GranularScope' do
    organization { namespace&.organization || association(:common_organization) }
    namespace
    permissions { [:create_issue] }

    trait :personal_projects do
      access { :personal_projects }
    end

    trait :all_memberships do
      namespace { nil }
      access { :all_memberships }
    end

    trait :selected_memberships do
      access { :selected_memberships }
    end

    trait :user do
      namespace { nil }
      access { :user }
    end

    trait :instance do
      namespace { nil }
      access { :instance }
    end
  end
end
