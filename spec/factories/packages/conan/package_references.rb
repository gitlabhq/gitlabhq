# frozen_string_literal: true

FactoryBot.define do
  factory :conan_package_reference, class: 'Packages::Conan::PackageReference' do
    package { association(:conan_package) }
    project { association(:project) }
    recipe_revision { association(:conan_recipe_revision, package: package, project: project) }
    info do
      {
        settings: { os: 'Linux', arch: 'x86_64' },
        requires: ['libA/1.0@user/testing'],
        options: { fPIC: true },
        otherProperties: 'some_value'
      }
    end
    sequence(:reference) { |n| Digest::SHA1.hexdigest(n.to_s) } # rubocop:disable Fips/SHA1 -- The conan registry is not FIPS compliant
  end
end
