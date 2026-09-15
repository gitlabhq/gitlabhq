# frozen_string_literal: true

FactoryBot.define do
  factory :supply_chain_signing_certificate, class: 'SupplyChain::SigningCertificate' do
    project factory: :project
    active { true }
    private_key { File.read(Rails.root.join('spec/fixtures/supply_chain/signing_key.key')) }
    certificate { File.read(Rails.root.join('spec/fixtures/supply_chain/signing_certificate.pem')) }

    trait :inactive do
      active { false }
    end
  end
end
