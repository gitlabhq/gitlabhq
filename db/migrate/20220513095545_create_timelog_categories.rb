# frozen_string_literal: true

class CreateTimelogCategories < Gitlab::Database::Migration[2.0]
  enable_lock_retries!

  def up
    create_table :timelog_categories do |t|
      t.references :namespace,
                   index: false,
                   null: false,
                   foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.decimal :billing_rate, precision: 18, scale: 4, default: 0
      t.boolean :billable, default: false, null: false
      t.text :name, null: false, limit: 255
      t.text :description, limit: 1024
      t.text :color, limit: 7, default: '#6699cc', null: false

      t.index 'namespace_id, LOWER(name)',
              unique: true,
              name: :index_timelog_categories_on_unique_name_per_namespace
    end
  end

  def down
    drop_table :timelog_categories
  end
end
