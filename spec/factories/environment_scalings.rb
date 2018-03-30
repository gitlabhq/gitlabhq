FactoryBot.define do
  factory :environment_scaling do
    environment
    sequence(:replicas) { |n| n }
  end
end
