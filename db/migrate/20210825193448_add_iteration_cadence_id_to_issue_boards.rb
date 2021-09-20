# frozen_string_literal: true

class AddIterationCadenceIdToIssueBoards < Gitlab::Database::Migration[1.0]
  enable_lock_retries!

  def change
    add_column :boards, :iteration_cadence_id, :bigint
  end
end
