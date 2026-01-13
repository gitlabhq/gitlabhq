# frozen_string_literal: true

FactoryBot.define do
  factory :granular_scope, class: 'Authz::GranularScope' do
    organization { namespace&.organization || association(:common_organization) }
    namespace { boundary ? boundary.namespace : association(:namespace) }
    permissions { [:create_member_role] }
    access { boundary&.access }

    transient do
      boundary { nil }
    end
  end
end
