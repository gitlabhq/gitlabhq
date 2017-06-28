FactoryGirl.define do
  factory :ci_project_variable, class: Ci::ProjectVariable do
    sequence(:key) { |n| "VARIABLE_#{n}" }
    value 'VARIABLE_VALUE'
    project factory: :empty_project

    trait(:protected) do
      protected true
    end
  end
end
