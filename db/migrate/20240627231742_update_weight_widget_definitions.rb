# frozen_string_literal: true

class UpdateWeightWidgetDefinitions < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  restrict_gitlab_migration gitlab_schema: :gitlab_main
  disable_ddl_transaction!

  EPIC_TYPE_ENUM = 7
  WEIGHT_WIDGET_NAME = 'Weight'
  WEIGHT_WIDGET_TYPE_ENUM = 8

  def up
    work_item_widget_definitions.reset_column_information

    work_item_widget_definitions.where(widget_type: WEIGHT_WIDGET_TYPE_ENUM)
      .update_all(widget_options: { 'editable' => true, 'rollup' => false })

    return unless epic_type

    work_item_widget_definitions.create!(
      widget_type: WEIGHT_WIDGET_TYPE_ENUM,
      widget_options: { 'editable' => false, 'rollup' => true },
      name: WEIGHT_WIDGET_NAME,
      work_item_type_id: epic_type.id
    )
  end

  def down
    if epic_type
      work_item_widget_definitions.where(
        namespace_id: nil,
        widget_type: WEIGHT_WIDGET_TYPE_ENUM,
        work_item_type_id: epic_type.id
      ).delete_all
    end

    work_item_widget_definitions.where(widget_type: WEIGHT_WIDGET_TYPE_ENUM)
      .update_all(widget_options: nil)
  end

  private

  def work_item_widget_definitions
    @work_item_widget_definitions ||= define_batchable_model('work_item_widget_definitions')
  end

  def work_item_types
    @work_item_types ||= define_batchable_model('work_item_types')
    @work_item_types.reset_column_information

    @work_item_types
  end

  def epic_type
    @epic_type ||= work_item_types.find_by_base_type_and_namespace_id(EPIC_TYPE_ENUM, nil)
  end
end
