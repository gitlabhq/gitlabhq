# frozen_string_literal: true

FactoryBot.define do
  factory :iam_outbox, class: 'Authn::IamOutbox' do
    organization
    entity_type { 'oauth_application' }
    sequence(:entity_id) { |n| n }
    event_type { :upsert }
    payload { {} }
  end
end
