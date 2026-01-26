# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_custom_type, class: 'WorkItems::TypesFramework::Custom::Type' do
    sequence(:name) { |n| "Custom Type #{n}" }
    icon_name { :work_item_feature }
    namespace { association(:group) }
    organization { nil }

    trait :with_organization do
      organization { association(:organization) }
      namespace { nil }
    end

    trait :converted_from_issue do
      converted_from_system_defined_type_identifier { 1 }
    end

    trait :converted_from_incident do
      converted_from_system_defined_type_identifier { 2 }
    end

    trait :converted_from_task do
      converted_from_system_defined_type_identifier { 5 }
    end
  end
end
