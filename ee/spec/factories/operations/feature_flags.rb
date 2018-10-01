FactoryBot.define do
  factory :operations_feature_flag, class: Operations::FeatureFlag do
    sequence(:name) { |n| "feature_flag_#{n}" }
    project
    active true
  end
end
