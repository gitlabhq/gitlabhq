# frozen_string_literal: true

class CreateCiRunnerControllerInstanceLevelScopings < Gitlab::Database::Migration[2.3]
  milestone '18.9'

  # -- factories exist in ee/spec/factories/ci/runner_controller_instance_level_scopings.rb
  def change
    create_table :ci_runner_controller_instance_level_scopings do |t|
      t.references :runner_controller, null: false,
        foreign_key: { to_table: :ci_runner_controllers, on_delete: :cascade },
        index: { unique: true, name: 'index_ci_rc_instance_level_scopings_on_runner_controller_id' }

      t.timestamps_with_timezone null: false
    end
  end
end
