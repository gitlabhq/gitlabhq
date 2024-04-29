# frozen_string_literal: true

FactoryBot.define do
  factory :ci_partition, class: 'Ci::Partition' do
    sequence(:id, 100)
  end
end
