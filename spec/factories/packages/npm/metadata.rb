# frozen_string_literal: true

FactoryBot.define do
  factory :npm_metadatum, class: 'Packages::Npm::Metadatum' do
    package { association(:npm_package) }

    package_json do
      {
        name: package.name,
        version: package.version,
        dist: {
          tarball: 'http://localhost/tarball.tgz',
          shasum: '1234567890'
        },
        scripts: {
          test: 'echo "Test"'
        }
      }
    end
  end
end
