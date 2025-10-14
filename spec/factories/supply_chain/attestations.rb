# frozen_string_literal: true

FactoryBot.define do
  factory :supply_chain_attestation, class: 'SupplyChain::Attestation' do
    project factory: :project
    build factory: [:ci_build, :success]
    predicate_kind { :provenance }
    predicate_type { "https://slsa.dev/provenance/v1" }
    subject_digest { Digest::SHA256.hexdigest("abc") }
    file { fixture_file_upload('spec/fixtures/supply_chain/attestation.json') }
  end
end
