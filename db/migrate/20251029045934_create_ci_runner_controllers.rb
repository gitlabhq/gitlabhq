# frozen_string_literal: true

class CreateCiRunnerControllers < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  # -- factories exist in spec/factories/ci/runner_controllers.rb
  def change
    create_table :ci_runner_controllers do |t|
      t.text :description, limit: 1024

      t.timestamps_with_timezone null: false
    end
  end
end
