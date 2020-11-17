# frozen_string_literal: true

FactoryBot.define do
  factory :package_file_build_info, class: 'Packages::PackageFileBuildInfo' do
    package_file

    trait :with_pipeline do
      association :pipeline, factory: [:ci_pipeline, :with_job]
    end
  end
end
