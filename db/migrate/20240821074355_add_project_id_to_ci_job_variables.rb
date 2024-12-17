# frozen_string_literal: true

class AddProjectIdToCiJobVariables < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def change
    add_column(:ci_job_variables, :project_id, :bigint) # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
  end
end
