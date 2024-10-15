# frozen_string_literal: true

class AddProjectIdToCiUnitTestFailures < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :ci_unit_test_failures, :project_id, :bigint
  end
end
