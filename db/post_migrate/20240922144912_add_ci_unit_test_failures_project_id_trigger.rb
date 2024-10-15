# frozen_string_literal: true

class AddCiUnitTestFailuresProjectIdTrigger < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def up
    install_sharding_key_assignment_trigger(
      table: :ci_unit_test_failures,
      sharding_key: :project_id,
      parent_table: :ci_unit_tests,
      parent_sharding_key: :project_id,
      foreign_key: :unit_test_id
    )
  end

  def down
    remove_sharding_key_assignment_trigger(
      table: :ci_unit_test_failures,
      sharding_key: :project_id,
      parent_table: :ci_unit_tests,
      parent_sharding_key: :project_id,
      foreign_key: :unit_test_id
    )
  end
end
