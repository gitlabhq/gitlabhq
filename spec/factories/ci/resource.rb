# frozen_string_literal: true

FactoryBot.define do
  factory :ci_resource, class: 'Ci::Resource' do
    resource_group factory: :ci_resource_group

    trait(:retained) do
      processable factory: :ci_build
      partition_id { processable.partition_id }
    end
  end
end
