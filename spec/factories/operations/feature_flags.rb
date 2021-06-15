# frozen_string_literal: true

FactoryBot.define do
  factory :operations_feature_flag, class: 'Operations::FeatureFlag' do
    sequence(:name) { |n| "feature_flag_#{n}" }
    project
    active { true }
    version { :new_version_flag }

    trait :legacy_flag do
      version { Operations::FeatureFlag.versions['legacy_flag'] }
    end

    trait :new_version_flag do
      version { Operations::FeatureFlag.versions['new_version_flag'] }
    end
  end
end
