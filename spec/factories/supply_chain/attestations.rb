# frozen_string_literal: true

FactoryBot.define do
  factory :supply_chain_attestation, class: 'SupplyChain::Attestation' do
    project factory: :project
    build factory: [:ci_build, :success]
    predicate_kind { :provenance }
    predicate_type { "https://slsa.dev/provenance/v1" }
    sequence(:subject_digest) { |n| Digest::SHA256.hexdigest("attestation-#{n}") }
    file { fixture_file_upload('spec/fixtures/supply_chain/attestation.json') }
    predicate_file { fixture_file_upload('spec/fixtures/supply_chain/predicate.json') }

    trait :with_error_status do
      status { 'error' }
    end
  end
end
