# frozen_string_literal: true

FactoryBot.define do
  factory :debian_project_distribution_key, class: 'Packages::Debian::ProjectDistributionKey' do
    distribution { association(:debian_project_distribution) }

    private_key { File.read(Rails.root.join('spec/fixtures/', 'private_key.asc')) }
    passphrase { '12345' }
    public_key { File.read(Rails.root.join('spec/fixtures/', 'public_key.asc')) }
    fingerprint { '12345' }

    factory :debian_group_distribution_key, class: 'Packages::Debian::GroupDistributionKey' do
      distribution { association(:debian_group_distribution) }
    end
  end
end
