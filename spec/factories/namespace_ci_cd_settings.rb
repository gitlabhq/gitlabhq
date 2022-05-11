# frozen_string_literal: true

FactoryBot.define do
  factory :namespace_ci_cd_settings, class: 'NamespaceCiCdSetting' do
    namespace
  end
end
