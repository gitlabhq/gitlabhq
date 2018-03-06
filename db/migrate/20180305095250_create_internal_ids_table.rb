class CreateInternalIdsTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    # TODO: use bigserial for id
    create_table :internal_ids do |t|
      t.integer :last_value, null: false
    end
  end

  def down
    drop_table :internal_ids
  end
end
