# frozen_string_literal: true

FactoryBot.define do
  factory :package_build_info, class: 'Packages::BuildInfo' do
    package { association(:generic_package) }

    trait :with_pipeline do
      association :pipeline, factory: [:ci_pipeline, :with_job]
    end
  end
end
