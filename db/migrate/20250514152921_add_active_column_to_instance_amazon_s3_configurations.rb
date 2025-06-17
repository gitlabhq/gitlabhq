# frozen_string_literal: true

class AddActiveColumnToInstanceAmazonS3Configurations < Gitlab::Database::Migration[2.3]
  milestone '18.1'

  def up
    add_column :audit_events_instance_amazon_s3_configurations, :active, :boolean, null: false, default: true
  end

  def down
    remove_column :audit_events_instance_amazon_s3_configurations, :active
  end
end
