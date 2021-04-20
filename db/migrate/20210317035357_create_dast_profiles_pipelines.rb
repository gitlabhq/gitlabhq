# frozen_string_literal: true

class CreateDastProfilesPipelines < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    table_comment = { owner: 'group::dynamic analysis', description: 'Join table between DAST Profiles and CI Pipelines' }

    create_table :dast_profiles_pipelines, primary_key: [:dast_profile_id, :ci_pipeline_id], comment: table_comment.to_json do |t|
      t.bigint :dast_profile_id, null: false
      t.bigint :ci_pipeline_id, null: false

      t.index :ci_pipeline_id, unique: true, name: :index_dast_profiles_pipelines_on_ci_pipeline_id
    end
  end

  def down
    drop_table :dast_profiles_pipelines
  end
end
