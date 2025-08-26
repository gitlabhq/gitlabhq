# frozen_string_literal: true

FactoryBot.define do
  factory :slsa_attestation, class: 'Ci::Slsa::Attestation' do
    project factory: :project
    build factory: [:ci_build, :success]
    predicate_kind { :provenance }
    predicate_type { "https://slsa.dev/provenance/v1" }
    subject_digest { Digest::SHA256.hexdigest("abc") }
  end
end
