# frozen_string_literal: true

class CreateAuditEventsAmazonS3Configurations < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  UNIQUE_NAME = "unique_amazon_s3_configurations_namespace_id_and_name"
  UNIQUE_BUCKET_NAME = "unique_amazon_s3_configurations_namespace_id_and_bucket_name"

  def change
    create_table :audit_events_amazon_s3_configurations do |t|
      t.timestamps_with_timezone null: false
      t.references :namespace, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.text :access_key_xid, null: false, limit: 128
      t.text :name, null: false, limit: 72
      t.text :bucket_name, null: false, limit: 63
      t.text :aws_region, null: false, limit: 50
      t.binary :encrypted_secret_access_key, null: false
      t.binary :encrypted_secret_access_key_iv, null: false

      t.index [:namespace_id, :name], unique: true, name: UNIQUE_NAME
      t.index [:namespace_id, :bucket_name], unique: true, name: UNIQUE_BUCKET_NAME
    end
  end
end
