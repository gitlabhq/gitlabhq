# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_settings, class: 'NamespaceSetting' do
    namespace
  end
end
