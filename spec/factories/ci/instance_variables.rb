# frozen_string_literal: true

FactoryBot.define do
  factory :ci_instance_variable, class: 'Ci::InstanceVariable' do
    sequence(:key) { |n| "VARIABLE_#{n}" }
    value { 'VARIABLE_VALUE' }
    masked { false }

    trait(:protected) do
      add_attribute(:protected) { true }
    end
  end
end
