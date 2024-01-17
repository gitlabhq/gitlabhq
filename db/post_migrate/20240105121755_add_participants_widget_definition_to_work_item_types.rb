# frozen_string_literal: true

class AddParticipantsWidgetDefinitionToWorkItemTypes < Gitlab::Database::Migration[2.2]
  milestone '16.9'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  WIDGET_NAME = 'Participants'
  WIDGET_ENUM_VALUE = 20

  def up
    widgets = []

    work_item_types = define_batchable_model('work_item_types')
    work_item_types.each_batch do |work_item_types|
      work_item_types.each do |type|
        widgets << {
          work_item_type_id: type.id,
          name: WIDGET_NAME,
          widget_type: WIDGET_ENUM_VALUE
        }
      end
    end

    return if widgets.empty?

    work_item_widget_definitions.upsert_all(
      widgets,
      unique_by: :index_work_item_widget_definitions_on_default_witype_and_name
    )
  end

  def down
    work_item_widget_definitions.where(name: WIDGET_NAME).delete_all
  end

  private

  def work_item_widget_definitions
    define_batchable_model('work_item_widget_definitions')
  end
end
