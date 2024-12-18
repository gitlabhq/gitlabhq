# frozen_string_literal: true

FactoryBot.define do
  factory :work_item_type, class: 'WorkItems::Type' do
    # Use Issue as the default type to mirror app code where unless specified, the type is Issue
    name { ::WorkItems::Type::BASE_TYPES[:issue][:name] }
    base_type { ::WorkItems::Type::BASE_TYPES[:issue][:enum_value] }
    icon_name { ::WorkItems::Type::BASE_TYPES[:issue][:icon_name] }

    transient do
      default { true }
      widgets { [] }
    end

    initialize_with do
      next WorkItems::Type.new(attributes) unless default

      type_base_attributes = attributes.with_indifferent_access.slice(:base_type, :name)

      # Expect base_types to exist on the DB
      WorkItems::Type.find_or_initialize_by(type_base_attributes)
    end

    # non_default work item types don't exist in production. This trait only exists to simplify work item type
    # specific specs and prevent coupling with existing default types
    trait :non_default do
      default { false }
      sequence(:id, 100) { |n| n }
      sequence(:correct_id, 100) { |n| n }
      icon_name { 'issue-type-non-default' }
      sequence(:name) { |n| "Work item type #{n}" }
    end

    # Define a trait for each default work item type with the same attributes as the seed file
    ::WorkItems::Type::BASE_TYPES.each do |type_name, attributes|
      trait type_name do
        base_type { attributes[:enum_value] }
        name { attributes[:name] }
      end
    end

    # Pass widgets you want to create for non-default types like
    #
    # create(:work_item_type, :non_default, widgets: [:time_tracking, :weight])
    #
    # or
    #
    # create(:work_item_type, :non_default, widgets: [
    #   { widget_type: :crm_contacts, name: 'CrmContacts' },
    #   { widget_type: :weight, name: 'Weight', widget_options: { rollup: false, editable: true }}
    # ])
    #
    after(:create) do |work_item_type, evaluator|
      next unless evaluator.widgets.any?

      evaluator.widgets.each do |item|
        if item.is_a?(Symbol)
          args = {
            widget_type: item,
            name: item.to_s.tr('_', ' ').camelize
          }
        elsif item.is_a?(Hash)
          args = item
        else
          next
        end

        work_item_type.widget_definitions.create!(args)
      end
    end
  end
end
