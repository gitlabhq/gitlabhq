# frozen_string_literal: true

FactoryBot.define do
  factory :protected_tag_create_access_level, class: 'ProtectedTag::CreateAccessLevel' do
    deploy_key { nil }
    protected_tag
    access_level { Gitlab::Access::DEVELOPER }
  end
end
