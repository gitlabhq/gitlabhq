FactoryBot.define do
  factory :environment_scaling do
    environment
    sequence(:production_replicas) { |n| n }
  end
end
