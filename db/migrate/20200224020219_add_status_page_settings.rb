# frozen_string_literal: true

class AddStatusPageSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  def change
    create_table :status_page_settings, id: false do |t|
      t.references :project, index: true, primary_key: true, foreign_key: { on_delete: :cascade }, unique: true, null: false
      t.timestamps_with_timezone null: false
      t.boolean :enabled, default: false, null: false
      t.string :aws_s3_bucket_name, limit: 63, null: false
      t.string :aws_region, limit: 255, null: false
      t.string :aws_access_key, limit: 255, null: false
      t.string :encrypted_aws_secret_key, limit: 255, null: false
      t.string :encrypted_aws_secret_key_iv, limit: 255, null: false
    end
  end
  # rubocop:enable Migration/PreventStrings
end
