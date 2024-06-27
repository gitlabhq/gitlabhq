# frozen_string_literal: true

class DropTableDastSiteProfilesPipelines < Gitlab::Database::Migration[2.2]
  milestone '17.2'
  disable_ddl_transaction!

  def up
    drop_table :dast_site_profiles_pipelines if table_exists? :dast_site_profiles_pipelines
  end

  def down
    unless table_exists?(:dast_site_profiles_pipelines)
      create_table :dast_site_profiles_pipelines, id: false do |t|
        t.bigint :dast_site_profile_id, null: false
        t.bigint :ci_pipeline_id, null: false
        t.index [:dast_site_profile_id, :ci_pipeline_id], name: :dast_site_profiles_pipelines_pkey, unique: true
        t.index :ci_pipeline_id, name: :index_dast_site_profiles_pipelines_on_ci_pipeline_id, unique: true
      end
    end

    add_primary_key_using_index(
      :dast_site_profiles_pipelines,
      :dast_site_profiles_pipelines_pkey,
      :dast_site_profiles_pipelines_pkey
    )

    return if foreign_key_exists?(:dast_site_profiles_pipelines, :dast_site_profiles, name: :fk_cf05cf8fe1)

    add_concurrent_foreign_key(
      :dast_site_profiles_pipelines,
      :dast_site_profiles,
      column: :dast_site_profile_id,
      name: :fk_cf05cf8fe1)

    execute(<<~SQL)
     COMMENT ON TABLE dast_site_profiles_pipelines IS '{"owner":"group::dynamic analysis","description":"Join table between DAST Site Profiles and CI Pipelines"}';
    SQL
  end
end
