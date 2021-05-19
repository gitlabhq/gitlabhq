# frozen_string_literal: true

class CreateDastSiteProfilesPipelines < ActiveRecord::Migration[6.0]
  def up
    table_comment = { owner: 'group::dynamic analysis', description: 'Join table between DAST Site Profiles and CI Pipelines' }

    create_table :dast_site_profiles_pipelines, primary_key: [:dast_site_profile_id, :ci_pipeline_id], comment: table_comment.to_json do |t|
      t.bigint :dast_site_profile_id, null: false
      t.bigint :ci_pipeline_id, null: false

      t.index :ci_pipeline_id, unique: true, name: :index_dast_site_profiles_pipelines_on_ci_pipeline_id
    end
  end

  def down
    drop_table :dast_site_profiles_pipelines
  end
end
