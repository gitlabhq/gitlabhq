# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_callout, class: 'Users::NamespaceCallout' do
    feature_name { :invite_members_banner }

    user
    namespace
  end
end
