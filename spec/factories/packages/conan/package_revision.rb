# frozen_string_literal: true

FactoryBot.define do
  factory :conan_package_revision, class: 'Packages::Conan::PackageRevision' do
    package { association(:conan_package) }
    association :project
    package_reference { association(:conan_package_reference) }
    sequence(:revision) { |n| Digest::SHA1.hexdigest(n.to_s) } # rubocop:disable Fips/SHA1 -- The conan registry is not FIPS compliant
  end
end
