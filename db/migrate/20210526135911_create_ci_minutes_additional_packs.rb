# frozen_string_literal: true

class CreateCiMinutesAdditionalPacks < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  def up
    create_table_with_constraints :ci_minutes_additional_packs, if_not_exists: true do |t|
      t.timestamps_with_timezone

      t.references  :namespace, index: false, null: false, foreign_key: { on_delete: :cascade }
      t.date        :expires_at, null: true
      t.integer     :number_of_minutes, null: false
      t.text        :purchase_xid, null: true
      t.text_limit  :purchase_xid, 32

      t.index [:namespace_id, :purchase_xid], name: 'index_ci_minutes_additional_packs_on_namespace_id_purchase_xid'
    end
  end

  def down
    with_lock_retries do
      drop_table :ci_minutes_additional_packs
    end
  end
end
