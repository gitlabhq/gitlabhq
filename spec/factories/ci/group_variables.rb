# frozen_string_literal: true

FactoryBot.define do
  factory :ci_group_variable, class: 'Ci::GroupVariable' do
    sequence(:key) { |n| "VARIABLE_#{n}" }
    value { 'VARIABLE_VALUE' }
    masked { false }
    variable_type { :env_var }

    trait(:protected) do
      add_attribute(:protected) { true }
    end

    trait(:file) do
      variable_type { :file }
    end

    group factory: :group
  end
end
