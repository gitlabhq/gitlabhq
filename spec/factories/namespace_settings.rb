# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_settings, class: 'NamespaceSetting' do
    default_branch_protection_defaults { ::Gitlab::Access::BranchProtection.protection_none }

    namespace
  end
end
