# frozen_string_literal: true

class AddIndexForLabelAppliedToIssuableSla < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'index_issuable_slas_on_due_at_id_label_applied_issuable_closed'

  def up
    add_concurrent_index :issuable_slas, [:due_at, :id], name: INDEX_NAME, where: 'label_applied = FALSE AND issuable_closed = FALSE'
  end

  def down
    remove_concurrent_index_by_name :issuable_slas, INDEX_NAME
  end
end
