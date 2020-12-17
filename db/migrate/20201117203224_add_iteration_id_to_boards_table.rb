# frozen_string_literal: true

class AddIterationIdToBoardsTable < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    with_lock_retries do
      add_column :boards, :iteration_id, :bigint
    end
  end

  def down
    with_lock_retries do
      remove_column :boards, :iteration_id
    end
  end
end
