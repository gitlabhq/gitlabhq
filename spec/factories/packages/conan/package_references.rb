# frozen_string_literal: true

FactoryBot.define do
  factory :conan_package_reference, class: 'Packages::Conan::PackageReference' do
    package { association(:conan_package, without_package_references: true, without_package_files: true) }
    project { package.project }
    recipe_revision { package.conan_recipe_revisions.first }
    info do
      {
        settings: { os: 'Linux', arch: 'x86_64' },
        requires: ['libA/1.0@user/testing'],
        options: { fPIC: 'True' },
        otherProperties: 'some_value'
      }
    end
    sequence(:reference) { |n| Digest::SHA1.hexdigest(n.to_s) } # rubocop:disable Fips/SHA1 -- The conan registry is not FIPS compliant
  end
end
