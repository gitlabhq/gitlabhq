# frozen_string_literal: true

class CreateOrganizationSettings < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    create_table :organization_settings, id: false do |t|
      t.references :organization, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
      t.timestamps_with_timezone null: false
      t.jsonb :settings, default: {}, null: false
    end
  end
end
