# frozen_string_literal: true

FactoryBot.define do
  factory :container_registry_data_repair_detail, class: 'ContainerRegistry::DataRepairDetail' do
    project
    updated_at { 1.hour.ago }

    trait :ongoing do
      status { :ongoing }
    end

    trait :completed do
      status { :completed }
    end

    trait :failed do
      status { :failed }
    end
  end
end
