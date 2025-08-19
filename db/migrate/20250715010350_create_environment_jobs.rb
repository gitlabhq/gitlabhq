# frozen_string_literal: true

class CreateEnvironmentJobs < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    create_table :job_environments do |t| # rubocop:disable Migration/EnsureFactoryForTable -- https://gitlab.com/gitlab-org/gitlab/-/issues/468630
      t.bigint :project_id, null: false, index: true
      t.bigint :environment_id, null: false, index: true
      t.bigint :ci_pipeline_id, null: false, index: true
      t.bigint :ci_job_id, null: false
      t.bigint :deployment_id, index: true
      t.text :expanded_environment_name, limit: 255, null: false
      t.jsonb :options, null: false, default: {}

      t.index [:ci_job_id, :environment_id], unique: true
    end
  end
end
