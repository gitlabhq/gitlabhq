# frozen_string_literal: true

FactoryBot.define do
  factory :debian_project_distribution, class: 'Packages::Debian::ProjectDistribution' do
    container { association(:project) }

    sequence(:codename) { |n| "project-dist-#{n}" }

    factory :debian_group_distribution, class: 'Packages::Debian::GroupDistribution' do
      container { association(:group) }

      sequence(:codename) { |n| "group-dist-#{n}" }
    end

    trait(:with_file) do
      file_signature do
        <<~EOF
        -----BEGIN PGP SIGNATURE-----

        ABC
        -----BEGIN PGP SIGNATURE-----
        EOF
      end

      after(:build) do |distribution, evaluator|
        distribution.file = fixture_file_upload('spec/fixtures/packages/debian/distribution/Release')
        distribution.signed_file = fixture_file_upload('spec/fixtures/packages/debian/distribution/InRelease')
      end
    end

    trait(:object_storage) do
      file_store { Packages::PackageFileUploader::Store::REMOTE }
    end
  end
end
