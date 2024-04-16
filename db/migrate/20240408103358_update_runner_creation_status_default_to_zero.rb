# frozen_string_literal: true

class UpdateRunnerCreationStatusDefaultToZero < Gitlab::Database::Migration[2.2]
  milestone '16.11'

  def change
    change_column_default :ci_runners, :creation_state, from: 100, to: 0
  end
end
