# frozen_string_literal: true

class CreateObservabilityGroupO11ySettings < Gitlab::Database::Migration[2.3]
  milestone '18.2'

  def change
    create_table :observability_group_o11y_settings do |t|
      t.references :group, null: false, foreign_key: { to_table: :namespaces, on_delete: :cascade }, unique: true
      t.text :o11y_service_url, null: false, limit: 255
      t.text :o11y_service_user_email, null: false, limit: 255
      t.jsonb :o11y_service_password, null: false
      t.jsonb :o11y_service_post_message_encryption_key, null: false

      t.timestamps_with_timezone null: false
    end
  end
end
