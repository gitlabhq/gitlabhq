FactoryGirl.define do
  factory :ci_variable, class: Ci::Variable do
    sequence(:key) { |n| "VARIABLE_#{n}" }
    value 'VARIABLE_VALUE'

    trait(:protected) do
      protected true
    end

    factory :ci_project_variable, class: Ci::ProjectVariable do
      project factory: :empty_project
    end

    factory :ci_group_variable, class: Ci::GroupVariable do
      group factory: :group
    end
  end
end
