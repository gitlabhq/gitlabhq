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
      current_from { Time.current }
    end

    trait :active do
      status { 3 }
      current_from { 1.month.ago }
      current_until { 1.week.ago }
    end
  end
end
