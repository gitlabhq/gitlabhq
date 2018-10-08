FactoryBot.define do
  factory :operations_feature_flags_client, class: Operations::FeatureFlagsClient do
    project
  end
end
