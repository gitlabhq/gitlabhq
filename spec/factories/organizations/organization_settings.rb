# frozen_string_literal: true

FactoryBot.define do
  factory :organization_setting, class: 'Organizations::OrganizationSetting' do
    organization { association(:organization) }
  end
end
