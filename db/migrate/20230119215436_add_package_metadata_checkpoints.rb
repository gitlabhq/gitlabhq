# frozen_string_literal: true

class AddPackageMetadataCheckpoints < Gitlab::Database::Migration[2.1]
  def up
    create_table :pm_checkpoints, id: false do |t|
      t.integer :sequence, null: false
      t.timestamps_with_timezone
      t.integer :purl_type, null: false, primary_key: true
      t.integer :chunk, null: false, limit: 2
    end

    change_column(:pm_checkpoints, :purl_type, :integer, limit: 2)
    drop_sequence(:pm_checkpoints, :purl_type, 'pm_checkpoints_purl_type_seq')
  end

  def down
    drop_table :pm_checkpoints
  end
end
