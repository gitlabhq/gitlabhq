# frozen_string_literal: true

class AddMissingIndexesForForeignKeys < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index(:application_settings, :usage_stats_set_by_user_id)
    add_concurrent_index(:ci_pipeline_schedules, :owner_id)
    add_concurrent_index(:ci_trigger_requests, :trigger_id)
    add_concurrent_index(:ci_triggers, :owner_id)
    add_concurrent_index(:clusters_applications_helm, :cluster_id, unique: true)
    add_concurrent_index(:clusters_applications_ingress, :cluster_id, unique: true)
    add_concurrent_index(:clusters_applications_jupyter, :cluster_id, unique: true)
    add_concurrent_index(:clusters_applications_jupyter, :oauth_application_id)
    add_concurrent_index(:clusters_applications_knative, :cluster_id, unique: true)
    add_concurrent_index(:clusters_applications_prometheus, :cluster_id, unique: true)
    add_concurrent_index(:fork_network_members, :forked_from_project_id)
    add_concurrent_index(:internal_ids, :namespace_id)
    add_concurrent_index(:internal_ids, :project_id)
    add_concurrent_index(:issues, :closed_by_id)
    add_concurrent_index(:label_priorities, :label_id)
    add_concurrent_index(:merge_request_metrics, :merged_by_id)
    add_concurrent_index(:merge_request_metrics, :latest_closed_by_id)
    add_concurrent_index(:oauth_openid_requests, :access_grant_id)
    add_concurrent_index(:project_deploy_tokens, :deploy_token_id)
    add_concurrent_index(:protected_tag_create_access_levels, :group_id)
    add_concurrent_index(:subscriptions, :project_id)
    add_concurrent_index(:user_statuses, :user_id)
    add_concurrent_index(:users, :accepted_term_id)
  end

  def down
    remove_concurrent_index(:application_settings, :usage_stats_set_by_user_id)
    remove_concurrent_index(:ci_pipeline_schedules, :owner_id)
    remove_concurrent_index(:ci_trigger_requests, :trigger_id)
    remove_concurrent_index(:ci_triggers, :owner_id)
    remove_concurrent_index(:clusters_applications_helm, :cluster_id, unique: true)
    remove_concurrent_index(:clusters_applications_ingress, :cluster_id, unique: true)
    remove_concurrent_index(:clusters_applications_jupyter, :cluster_id, unique: true)
    remove_concurrent_index(:clusters_applications_jupyter, :oauth_application_id)
    remove_concurrent_index(:clusters_applications_knative, :cluster_id, unique: true)
    remove_concurrent_index(:clusters_applications_prometheus, :cluster_id, unique: true)
    remove_concurrent_index(:fork_network_members, :forked_from_project_id)
    remove_concurrent_index(:internal_ids, :namespace_id)
    remove_concurrent_index(:internal_ids, :project_id)
    remove_concurrent_index(:issues, :closed_by_id)
    remove_concurrent_index(:label_priorities, :label_id)
    remove_concurrent_index(:merge_request_metrics, :merged_by_id)
    remove_concurrent_index(:merge_request_metrics, :latest_closed_by_id)
    remove_concurrent_index(:oauth_openid_requests, :access_grant_id)
    remove_concurrent_index(:project_deploy_tokens, :deploy_token_id)
    remove_concurrent_index(:protected_tag_create_access_levels, :group_id)
    remove_concurrent_index(:subscriptions, :project_id)
    remove_concurrent_index(:user_statuses, :user_id)
    remove_concurrent_index(:users, :accepted_term_id)
  end
end
