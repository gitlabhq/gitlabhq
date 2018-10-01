# frozen_string_literal: true

class CleanupRedundantIndexes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # redundant to index_ci_pipelines_on_project_id_and_sha and index_ci_pipelines_on_project_id_and_ref_and_status_and_id
    remove_concurrent_index :ci_pipelines, :project_id
    # redundant to index_ci_stages_on_pipeline_id_and_position and index_ci_stages_on_pipeline_id_and_name
    remove_concurrent_index :ci_stages, :pipeline_id
    # redundant to index_container_repositories_on_project_id_and_name
    remove_concurrent_index :container_repositories, :project_id
    # redundant to index_notifications_on_user_id_and_source_id_and_source_type
    remove_concurrent_index :notification_settings, :user_id
    # redundant to index_pages_domains_on_project_id_and_enabled_until
    remove_concurrent_index :pages_domains, :project_id
    # redundant to index_pages_domains_on_verified_at_and_enabled_until
    remove_concurrent_index :pages_domains, :verified_at
    # redundant to taggings_idx
    remove_concurrent_index :taggings, :tag_id
    # redundant to index_taggings_on_taggable_id_and_taggable_type_and_context
    remove_concurrent_index :taggings, [:taggable_id, :taggable_type]
    # redundant to term_agreements_unique_index
    remove_concurrent_index :term_agreements, :user_id
  end

  def down
    add_concurrent_index :ci_pipelines, :project_id
    add_concurrent_index :ci_stages, :pipeline_id
    add_concurrent_index :container_repositories, :project_id
    add_concurrent_index :notification_settings, :user_id
    add_concurrent_index :pages_domains, :project_id
    add_concurrent_index :pages_domains, :verified_at
    add_concurrent_index :taggings, :tag_id
    add_concurrent_index :taggings, [:taggable_id, :taggable_type]
    add_concurrent_index :term_agreements, :user_id
  end
end
