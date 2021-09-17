# frozen_string_literal: true

class AddFkToIterationCadenceIdOnBoards < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  INDEX_NAME = 'index_boards_on_iteration_cadence_id'

  def up
    add_concurrent_index :boards, :iteration_cadence_id, name: INDEX_NAME
    add_concurrent_foreign_key :boards, :iterations_cadences, column: :iteration_cadence_id
  end

  def down
    with_lock_retries do
      remove_foreign_key_if_exists :boards, column: :iteration_cadence_id
    end
    remove_concurrent_index_by_name :boards, INDEX_NAME
  end
end
