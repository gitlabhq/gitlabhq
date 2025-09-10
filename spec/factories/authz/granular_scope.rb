# frozen_string_literal: true

FactoryBot.define do
  factory :granular_scope, class: 'Authz::GranularScope' do
    organization { namespace&.organization || association(:common_organization) }
    namespace
    permissions { [:create_issue] }

    trait :instance do
      namespace { nil }
    end
  end
end
