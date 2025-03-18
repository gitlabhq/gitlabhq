# frozen_string_literal: true

class CreateCiProjectsWithPipelineVariables < Gitlab::Database::Migration[2.2]
  milestone '17.10'

  def change
    create_table(:projects_with_pipeline_variables, if_not_exists: true, id: false) do |t| # rubocop:disable Migration/EnsureFactoryForTable -- factory at ci/project_with_pipeline_variable.rb
      t.references :project, primary_key: true, default: nil, index: false, foreign_key: { on_delete: :cascade }
    end
  end
end
