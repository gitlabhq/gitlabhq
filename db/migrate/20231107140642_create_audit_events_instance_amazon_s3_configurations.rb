# frozen_string_literal: true

class CreateAuditEventsInstanceAmazonS3Configurations < Gitlab::Database::Migration[2.2]
  enable_lock_retries!
  milestone '16.7'

  UNIQUE_NAME = "unique_instance_amazon_s3_configurations_name"
  UNIQUE_BUCKET_NAME = "unique_instance_amazon_s3_configurations_bucket_name"

  def change
    create_table :audit_events_instance_amazon_s3_configurations do |t|
      t.timestamps_with_timezone null: false
      t.text :access_key_xid, null: false, limit: 128
      t.text :name, null: false, limit: 72
      t.text :bucket_name, null: false, limit: 63
      t.text :aws_region, null: false, limit: 50
      t.binary :encrypted_secret_access_key, null: false
      t.binary :encrypted_secret_access_key_iv, null: false

      t.index [:name], unique: true, name: UNIQUE_NAME
      t.index [:bucket_name], unique: true, name: UNIQUE_BUCKET_NAME
    end
  end
end
