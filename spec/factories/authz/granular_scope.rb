# frozen_string_literal: true

FactoryBot.define do
  factory :granular_scope, class: 'Authz::GranularScope' do
    organization { namespace&.organization || association(:common_organization) }
    namespace
    permissions { [:create_issue] }

    trait :standalone do
      namespace { nil }
    end

    trait :all_membership_namespaces do
      namespace { nil }
      all_membership_namespaces { true }
    end
  end
end
