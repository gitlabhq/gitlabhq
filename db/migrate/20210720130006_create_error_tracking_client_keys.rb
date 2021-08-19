# frozen_string_literal: true

class CreateErrorTrackingClientKeys < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table_with_constraints :error_tracking_client_keys do |t|
      t.references :project,
        index: true,
        null: false,
        foreign_key: { on_delete: :cascade }

      t.boolean :active, default: true, null: false
      t.text :public_key, null: false
      t.text_limit :public_key, 255

      t.timestamps_with_timezone
    end
  end

  def down
    drop_table :error_tracking_client_keys
  end
end
