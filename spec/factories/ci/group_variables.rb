# frozen_string_literal: true

FactoryBot.define do
  factory :ci_group_variable, class: 'Ci::GroupVariable' do
    sequence(:key) { |n| "VARIABLE_#{n}" }
    value { 'VARIABLE_VALUE' }
    masked { false }

    trait(:protected) do
      add_attribute(:protected) { true }
    end

    group factory: :group
  end
end
