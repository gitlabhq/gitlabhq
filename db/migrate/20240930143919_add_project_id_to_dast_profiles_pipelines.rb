# frozen_string_literal: true

class AddProjectIdToDastProfilesPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    add_column :dast_profiles_pipelines, :project_id, :bigint
  end
end
