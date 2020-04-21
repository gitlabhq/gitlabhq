# frozen_string_literal: true

class CreateClusterProvidersAws < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  # rubocop:disable Migration/PreventStrings
  # rubocop:disable Migration/AddLimitToTextColumns
  def change
    create_table :cluster_providers_aws do |t|
      t.references :cluster, null: false, type: :bigint, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :created_by_user, type: :integer, foreign_key: { on_delete: :nullify, to_table: :users }

      t.integer :num_nodes, null: false
      t.integer :status, null: false

      t.timestamps_with_timezone null: false

      t.string :key_name, null: false, limit: 255
      t.string :role_arn, null: false, limit: 2048
      t.string :region, null: false, limit: 255
      t.string :vpc_id, null: false, limit: 255
      t.string :subnet_ids, null: false, array: true, default: [], limit: 255
      t.string :security_group_id, null: false, limit: 255
      t.string :instance_type, null: false, limit: 255

      t.string :access_key_id, limit: 255
      t.string :encrypted_secret_access_key_iv, limit: 255
      t.text :encrypted_secret_access_key
      t.text :session_token
      t.text :status_reason

      t.index [:cluster_id, :status]
    end
  end
  # rubocop:enable Migration/AddLimitToTextColumns
  # rubocop:enable Migration/PreventStrings
end
