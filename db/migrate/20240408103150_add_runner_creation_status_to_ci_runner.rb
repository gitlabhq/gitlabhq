# frozen_string_literal: true

class AddRunnerCreationStatusToCiRunner < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    add_column :ci_runners, :creation_state, :integer, limit: 2, default: 100, null: false
  end
end
