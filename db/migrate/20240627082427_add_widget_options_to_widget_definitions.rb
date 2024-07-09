# frozen_string_literal: true

class AddWidgetOptionsToWidgetDefinitions < Gitlab::Database::Migration[2.2]
  milestone '17.2'

  def change
    add_column :work_item_widget_definitions, :widget_options, :jsonb, null: true
  end
end
