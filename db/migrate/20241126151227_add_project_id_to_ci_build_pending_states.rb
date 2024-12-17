# frozen_string_literal: true

class AddProjectIdToCiBuildPendingStates < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    add_column :ci_build_pending_states, :project_id, :bigint
  end
end
