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
          # WORK_ITEM_TYPE_ENUM_VALUE = 8
          # WIDGETS = [
          #   {
          #     name: 'Designs',
          #     widget_type: 22
          #   }
          # ]
          #
          # Then define the #up and down methods like this:
          # def up
          #   add_widget_definitions(type_enum_value: WORK_ITEM_TYPE_ENUM_VALUE, widgets: WIDGETS)
          # end
          #
          # def down
          #   remove_widget_definitions(type_enum_value: WORK_ITEM_TYPE_ENUM_VALUE, widgets: WIDGETS)
          # end
          #
          # Run a migration test for migrations that use this helper with:
          # require 'spec_helper'
          # require_migration!
          #
          # RSpec.describe AddDesignsAndDevelopmentWidgetsToTicketWorkItemType, :migration do
          #   it_behaves_like 'migration that adds widgets to a work item type'
          # end
          def add_widget_definitions(type_enum_value:, widgets:)
            work_item_type = migration_work_item_type.find_by(base_type: type_enum_value)

            # Work item type should exist in production applications, checking here to avoid failures
            # if inconsistent data is present.
            return say(type_missing_message(type_enum_value)) unless work_item_type

            widget_definitions = widgets.map { |w| w.merge(work_item_type_id: work_item_type.id) }

            migration_widget_definition.upsert_all(
              widget_definitions,
              on_duplicate: :skip
            )
          end

          def remove_widget_definitions(type_enum_value:, widgets:)
            work_item_type = migration_work_item_type.find_by(base_type: type_enum_value)

            return say(type_missing_message(type_enum_value)) unless work_item_type

            migration_widget_definition.where(
              work_item_type_id: work_item_type.id,
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
        end
      end
    end
  end
end
