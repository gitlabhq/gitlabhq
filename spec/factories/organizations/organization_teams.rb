# frozen_string_literal: true

FactoryBot.define do
  factory :organization_team, class: 'Organizations::Team' do
    organization { association :common_organization }

    sequence(:name) { |n| "Team #{n}" }
    sequence(:path) { |n| "team-#{n}" }
    description { 'A team' }
  end
end
