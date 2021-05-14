# frozen_string_literal: true

FactoryBot.define do
  factory :clusters_integrations_elastic_stack, class: 'Clusters::Integrations::ElasticStack' do
    cluster factory: %i(cluster provided_by_gcp)
    enabled { true }

    trait :disabled do
      enabled { false }
    end
  end
end
