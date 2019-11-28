# frozen_string_literal: true

class CreateImportFailures < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    create_table :import_failures do |t|
      t.integer :relation_index
      t.references :project, null: false, index: true
      t.datetime_with_timezone :created_at, null: false
      t.string :relation_key, limit: 64
      t.string :exception_class, limit: 128
      t.string :correlation_id_value, limit: 128, index: true
      t.string :exception_message, limit: 255
    end
  end
end
