# frozen_string_literal: true

FactoryBot.define do
  factory :organization_detail, class: 'Organizations::OrganizationDetail' do
    organization { association(:common_organization) }

    description { '_description_' }
    avatar { fixture_file_upload('spec/fixtures/dk.png') }
  end
end
