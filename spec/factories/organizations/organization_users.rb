# frozen_string_literal: true

FactoryBot.define do
  factory :organization_user, class: 'Organizations::OrganizationUser' do
    user
    organization
  end
end
