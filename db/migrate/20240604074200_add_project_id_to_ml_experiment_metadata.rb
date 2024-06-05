# frozen_string_literal: true

class AddProjectIdToMlExperimentMetadata < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    add_column :ml_experiment_metadata, :project_id, :bigint
  end
end
