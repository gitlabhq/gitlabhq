# frozen_string_literal: true

FactoryBot.define do
  factory :conan_package_revision, class: 'Packages::Conan::PackageRevision' do
    package do
      association(:conan_package, without_package_files: true)
    end

    project { package.project }
    package_reference { package.conan_package_references.first }
    sequence(:revision) { |n| Digest::SHA1.hexdigest(n.to_s) } # rubocop:disable Fips/SHA1 -- The conan registry is not FIPS compliant
  end
end
