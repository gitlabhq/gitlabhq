# frozen_string_literal: true

class AddLabelsToCiRunnerMachines < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  def change
    add_column :ci_runner_machines, :labels, :jsonb, default: {}, null: false, if_not_exists: true
  end
end
