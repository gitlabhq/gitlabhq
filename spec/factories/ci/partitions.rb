# frozen_string_literal: true

FactoryBot.define do
  factory :ci_partition, class: 'Ci::Partition' do
    sequence(:id, 100)
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
