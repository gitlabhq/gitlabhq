# frozen_string_literal: true

FactoryBot.define do
  factory :security_namespace_mirror, class: 'Security::NamespaceMirror' do
    namespace
    traversal_ids { namespace.traversal_ids }
    organization_id { namespace.organization_id }
  end
end
