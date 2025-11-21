# frozen_string_literal: true

FactoryBot.define do
  sequence(:ci_partition_id, 100)

  factory :ci_partition, class: 'Ci::Partition' do
    id { generate(:ci_partition_id) }
    status { 0 }

    trait :ready do
      status { 1 }
    end

    trait :current do
      status { 2 }
    end

    trait :active do
      status { 3 }
    end
  end
end
