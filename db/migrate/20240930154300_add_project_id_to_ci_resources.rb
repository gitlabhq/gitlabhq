# frozen_string_literal: true

class AddProjectIdToCiResources < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :ci_resources, :project_id, :bigint
  end
end
