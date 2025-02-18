# frozen_string_literal: true

module Gitlab
  module Database
    module MigrationHelpers
      module WorkItems
        module Widgets
          include Gitlab::Database::MigrationHelpers
          # Adds a list of widget definitions to a given work item type
          # Include module into your migration file with:
          # include Gitlab::Database::MigrationHelpers::WorkItems::Widgets
          #
          # Define the following constants in the migration class
          #
          # Use [8] for a single type
          # WORK_ITEM_TYPE_ENUM_VALUES = [8,9]
          #
          # Use only one array item to add a single widget
          # WIDGETS = [
          #   {
          #     name: 'Designs',
          #     widget_type: 22
          #   },
          #   {
          #     name: 'Weight',
          #     widget_type: 8,
          #     # widget_options is optional
          #     widget_options: {
          #       editable: true,
          #       rollup: false
          #     }
          #   },
          # ]
          #
          # Then define the #up and down methods like this:
          # def up
          #   add_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
          # end
          #
          # def down
          #   remove_widget_definitions(type_enum_values: WORK_ITEM_TYPE_ENUM_VALUES, widgets: WIDGETS)
          # end
          #
          # Run a migration test for migrations that use this helper with:
          # require 'spec_helper'
          # require_migration!
          #
          # RSpec.describe AddDesignsAndDevelopmentWidgetsToTicketWorkItemType, :migration do
          #   it_behaves_like 'migration that adds widgets to a work item type'
          # end
          def add_widget_definitions(widgets:, type_enum_value: nil, type_enum_values: [])
            enum_values = Array(type_enum_values) + [type_enum_value].compact

            work_item_types = migration_work_item_type.where(base_type: enum_values)

            # Work item types should exist in production applications, checking here to avoid failures
            # if inconsistent data is present.
            validate_work_item_types(enum_values, work_item_types)

            widget_definitions = work_item_types.flat_map do |work_item_type|
              widgets.map do |w|
                { work_item_type_id: work_item_type.id, widget_options: nil }.merge(w)
              end
            end

            return if widget_definitions.empty?

            migration_widget_definition.upsert_all(
              widget_definitions,
              on_duplicate: :skip
            )
          end

          def remove_widget_definitions(widgets:, type_enum_value: nil, type_enum_values: [])
            enum_values = Array(type_enum_values) + [type_enum_value].compact

            work_item_types = migration_work_item_type.where(base_type: enum_values)

            validate_work_item_types(enum_values, work_item_types)
            return if work_item_types.empty?

            migration_widget_definition.where(
              work_item_type_id: work_item_types.pluck(:id),
              widget_type: widgets.pluck(:widget_type)
            ).delete_all
          end

          private

          def migration_work_item_type
            define_batchable_model('work_item_types', base_class: self.class.superclass::MigrationRecord)
          end

          def migration_widget_definition
            define_batchable_model('work_item_widget_definitions', base_class: self.class.superclass::MigrationRecord)
          end

          def type_missing_message(type_enum_value)
            <<~MESSAGE.chomp
              Work item type with enum value #{type_enum_value} does not exist,
              skipping widget processing.
            MESSAGE
          end

          def validate_work_item_types(enum_values, work_item_types)
            found_types = work_item_types&.pluck(:base_type) || []
            missing_types = enum_values - found_types
            missing_types.each { |type| say(type_missing_message(type)) }
          end
        end
      end
    end
  end
end
