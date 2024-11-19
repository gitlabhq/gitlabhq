# frozen_string_literal: true

FactoryBot.define do
  factory :npm_metadatum, class: 'Packages::Npm::Metadatum' do
    package { association(:npm_package) }

    # TODO: Remove `legacy_package) with the rollout of the FF npm_extract_npm_package_model
    # https://gitlab.com/gitlab-org/gitlab/-/issues/501469
    package_json do
      {
        name: (package || legacy_package).name,
        version: (package || legacy_package).version,
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
