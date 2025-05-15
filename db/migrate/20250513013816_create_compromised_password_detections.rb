# frozen_string_literal: true

class CreateCompromisedPasswordDetections < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.1'

  def up
    create_table :compromised_password_detections do |t|
      t.timestamps_with_timezone null: false
      t.datetime_with_timezone :resolved_at, null: true, index: false
      t.references :user,
        null: false,
        foreign_key: { on_delete: :cascade },
        index: true

      t.index :user_id,
        name: "index_unresolved_compromised_password_detection_on_user_id",
        unique: true,
        where: "resolved_at IS NULL"
    end
  end

  def down
    drop_table :compromised_password_detections
  end
end
