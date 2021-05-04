# frozen_string_literal: true

# rubocop: disable Metrics/AbcSize
# rubocop: disable Migration/Datetime
# rubocop: disable Migration/PreventStrings
# rubocop: disable Migration/AddLimitToTextColumns
class BackportEnterpriseSchema < ActiveRecord::Migration[5.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  APPLICATION_SETTINGS_COLUMNS = [
    { type: :boolean, name: :elasticsearch_indexing, default: false, null: false },
    { type: :boolean, name: :elasticsearch_search, default: false, null: false },
    { type: :integer, name: :shared_runners_minutes, default: 0, null: false },
    { type: :bigint, name: :repository_size_limit, default: 0, null: true },
    { type: :string, name: :elasticsearch_url, default: "http://localhost:9200" },
    { type: :boolean, name: :elasticsearch_aws, default: false, null: false },
    { type: :string, name: :elasticsearch_aws_region, default: "us-east-1", null: true },
    { type: :string, name: :elasticsearch_aws_access_key, default: nil, null: true },
    { type: :string, name: :elasticsearch_aws_secret_access_key, default: nil, null: true },
    { type: :integer, name: :geo_status_timeout, default: 10, null: true },
    { type: :boolean, name: :elasticsearch_experimental_indexer, default: nil, null: true },
    { type: :boolean, name: :check_namespace_plan, default: false, null: false },
    { type: :integer, name: :mirror_max_delay, default: 300, null: false },
    { type: :integer, name: :mirror_max_capacity, default: 100, null: false },
    { type: :integer, name: :mirror_capacity_threshold, default: 50, null: false },
    { type: :boolean, name: :slack_app_enabled, default: false },
    { type: :string, name: :slack_app_id },
    { type: :string, name: :slack_app_secret },
    { type: :string, name: :slack_app_verification_token },
    { type: :boolean, name: :allow_group_owners_to_manage_ldap, default: true, null: false },
    { type: :integer, name: :default_project_creation, default: 2, null: false },
    { type: :string, name: :email_additional_text },
    { type: :integer, name: :file_template_project_id },
    { type: :boolean, name: :pseudonymizer_enabled, default: false, null: false },
    { type: :boolean, name: :snowplow_enabled, default: false, null: false },
    { type: :string, name: :snowplow_collector_uri },
    { type: :string, name: :snowplow_site_id },
    { type: :string, name: :snowplow_cookie_domain },
    { type: :integer, name: :custom_project_templates_group_id },
    { type: :boolean, name: :elasticsearch_limit_indexing, default: false, null: false },
    { type: :string, name: :geo_node_allowed_ips, default: '0.0.0.0/0, ::/0' }
  ].freeze

  NAMESPACE_COLUMNS = [
    { type: :integer, name: :custom_project_templates_group_id },
    { type: :integer, name: :file_template_project_id },
    { type: :string, name: :ldap_sync_error },
    { type: :datetime, name: :ldap_sync_last_successful_update_at },
    { type: :datetime, name: :ldap_sync_last_sync_at },
    { type: :datetime, name: :ldap_sync_last_update_at },
    { type: :integer, name: :plan_id },
    { type: :integer, name: :project_creation_level },
    { type: :bigint, name: :repository_size_limit },
    { type: :string, name: :saml_discovery_token },
    { type: :integer, name: :shared_runners_minutes_limit },
    { type: :datetime_with_timezone, name: :trial_ends_on },
    { type: :integer, name: :extra_shared_runners_minutes_limit }
  ].freeze

  PROJECT_MIRROR_DATA_COLUMNS = [
    { type: :datetime_with_timezone, name: :last_successful_update_at },
    { type: :datetime_with_timezone, name: :last_update_at },
    { type: :datetime, name: :last_update_scheduled_at },
    { type: :datetime, name: :last_update_started_at },
    { type: :datetime, name: :next_execution_timestamp }
  ].freeze

  PROJECTS_COLUMNS = [
    { type: :boolean, name: :disable_overriding_approvers_per_merge_request },
    { type: :string, name: :external_webhook_token },
    { type: :text, name: :issues_template },
    { type: :boolean, name: :merge_requests_author_approval },
    { type: :boolean, name: :merge_requests_disable_committers_approval },
    { type: :boolean, name: :merge_requests_require_code_owner_approval },
    { type: :text, name: :merge_requests_template },
    { type: :datetime, name: :mirror_last_successful_update_at },
    { type: :datetime, name: :mirror_last_update_at },
    { type: :boolean, name: :mirror_overwrites_diverged_branches },
    { type: :integer, name: :mirror_user_id },
    { type: :boolean, name: :only_mirror_protected_branches },
    { type: :boolean, name: :packages_enabled },
    { type: :boolean, name: :pull_mirror_available_overridden },
    { type: :bigint, name: :repository_size_limit },
    { type: :boolean, name: :require_password_to_approve }
  ].freeze

  USERS_COLUMNS = [
    { type: :datetime, name: :admin_email_unsubscribed_at },
    { type: :boolean, name: :email_opted_in },
    { type: :datetime, name: :email_opted_in_at },
    { type: :string, name: :email_opted_in_ip },
    { type: :integer, name: :email_opted_in_source_id },
    { type: :integer, name: :group_view },
    { type: :integer, name: :managing_group_id },
    { type: :text, name: :note },
    { type: :integer, name: :roadmap_layout, limit: 2 },
    { type: :boolean, name: :support_bot },
    { type: :integer, name: :bot_type, limit: 2 }
  ].freeze

  class ApplicationSetting < ActiveRecord::Base
    self.table_name = 'application_settings'
  end

  class ProtectedBranchMergeAccessLevels < ActiveRecord::Base
    self.table_name = 'protected_branch_merge_access_levels'
  end

  class ProtectedBranchPushAccessLevels < ActiveRecord::Base
    self.table_name = 'protected_branch_push_access_levels'
  end

  class Project < ActiveRecord::Base
    self.table_name = 'projects'
  end

  def up
    check_schema!

    create_missing_tables

    update_appearances
    update_application_settings
    update_boards_table
    update_clusters_applications_prometheus
    update_identities
    update_issues
    update_lists
    update_members
    update_merge_requests
    update_notes
    update_ci_builds
    update_environments
    update_namespaces
    update_notification_settings
    update_project_mirror_data
    update_project_statistics
    update_projects
    update_protected_branch_merge_access_levels
    update_protected_branch_push_access_levels
    update_resource_label_events
    update_user_preferences
    update_users
    update_web_hooks
    update_geo_nodes

    add_missing_foreign_keys
  end

  def down
    # This migration can not be reverted in a production environment, as doing
    # so would lead to data loss for existing EE installations.
    return if !Rails.env.test? && !Rails.env.development?

    remove_foreign_keys
    remove_tables

    revert_appearances
    revert_application_settings
    revert_boards_table
    revert_clusters_applications_prometheus
    revert_identities
    revert_issues
    revert_lists
    revert_members
    revert_merge_requests
    revert_notes
    revert_ci_builds
    revert_environments
    revert_namespaces
    revert_notification_settings
    revert_project_mirror_data
    revert_project_statistics
    revert_projects
    revert_protected_branch_merge_access_levels
    revert_protected_branch_push_access_levels
    revert_resource_label_events
    revert_user_preferences
    revert_users
    revert_web_hooks
  end

  def add_column_if_not_exists(table, name, *args)
    add_column(table, name, *args) unless column_exists?(table, name)
  end

  def remove_column_if_exists(table, column)
    remove_column(table, column) if column_exists?(table, column)
  end

  def drop_table_if_exists(table)
    # rubocop:disable Migration/DropTable
    drop_table(table) if table_exists?(table)
    # rubocop:enable Migration/DropTable
  end

  def add_column_with_default_if_not_exists(table, name, type, **args)
    unless column_exists?(table, name)
      add_column_with_default(table, name, type, **args) # rubocop:disable Migration/AddColumnWithDefault
    end
  end

  def add_missing_columns(table, columns)
    columns.each do |column|
      next if table.column_exists?(column[:name])

      # We can't use (public_)send here as this doesn't work with
      # `datetime_with_timezone` for some reason.
      table.column(
        column[:name],
        column[:type],
        default: column[:default],
        null: column.fetch(:null, true),
        limit: column[:limit]
      )
    end
  end

  def remove_columns(table, columns)
    columns.each do |column|
      remove_column_if_exists(table, column[:name])
    end
  end

  def create_table_if_not_exists(name, **args, &block)
    return if table_exists?(name)

    create_table(name, **args, &block)
  end

  def add_concurrent_foreign_key(source, target, column:, on_delete: nil, name: nil)
    # We don't want redundant VALIDATE CONSTRAINT statements to run for existing
    # foreign keys, as this can take a long time on large installations such as
    # GitLab.com.
    return if foreign_key_exists?(source, target, column: column)

    super
  end

  def update_appearances
    add_column_if_not_exists(:appearances, :updated_by, :integer)
  end

  def revert_appearances
    remove_column_if_exists(:namespaces, :updated_by)
  end

  def update_application_settings
    # In the CE schema this column allows NULL values even though there is a
    # default value. In EE this column is not allowed to be NULL. This means
    # that if we want to add a NOT NULL clause below, we must ensure no existing
    # data would violate this clause.
    ApplicationSetting
      .where(password_authentication_enabled_for_git: nil)
      .update_all(password_authentication_enabled_for_git: true)

    change_column_null(
      :application_settings,
      :password_authentication_enabled_for_git,
      false
    )

    # This table will only have a single row, and all operations here will be
    # very fast. As such we merge all of this into a single ALTER TABLE
    # statement.
    change_table(:application_settings) do |t|
      t.text(:help_text) unless t.column_exists?(:help_text)

      add_missing_columns(t, APPLICATION_SETTINGS_COLUMNS)
    end

    add_concurrent_index(
      :application_settings,
      :custom_project_templates_group_id
    )

    add_concurrent_index(
      :application_settings,
      :file_template_project_id
    )
  end

  def revert_application_settings
    change_column_null(
      :application_settings,
      :password_authentication_enabled_for_git,
      true
    )

    remove_concurrent_index(
      :application_settings,
      :custom_project_templates_group_id
    )

    remove_concurrent_index(
      :application_settings,
      :file_template_project_id
    )

    remove_columns(:application_settings, APPLICATION_SETTINGS_COLUMNS)
  end

  def update_boards_table
    add_column_if_not_exists(:boards, :milestone_id, :integer)
    add_column_if_not_exists(:boards, :weight, :integer)

    add_column_with_default_if_not_exists(
      :boards,
      :name,
      :string,
      default: 'Development'
    )

    add_concurrent_index(:boards, :milestone_id)
  end

  def revert_boards_table
    remove_concurrent_index(:boards, :milestone_id)
    remove_column_if_exists(:boards, :name)
    remove_column_if_exists(:boards, :weight)
    remove_column_if_exists(:boards, :milestone_id)
  end

  def update_clusters_applications_prometheus
    add_column_if_not_exists(
      :clusters_applications_prometheus,
      :encrypted_alert_manager_token,
      :string
    )

    add_column_if_not_exists(
      :clusters_applications_prometheus,
      :encrypted_alert_manager_token_iv,
      :string
    )

    add_column_if_not_exists(
      :clusters_applications_prometheus,
      :last_update_started_at,
      :datetime_with_timezone
    )
  end

  def revert_clusters_applications_prometheus
    remove_column_if_exists(
      :clusters_applications_prometheus,
      :encrypted_alert_manager_token
    )

    remove_column_if_exists(
      :clusters_applications_prometheus,
      :encrypted_alert_manager_token_iv
    )

    remove_column_if_exists(
      :clusters_applications_prometheus,
      :last_update_started_at
    )
  end

  def update_identities
    add_column_if_not_exists(:identities, :saml_provider_id, :integer)
    add_column_if_not_exists(:identities, :secondary_extern_uid, :string)

    add_concurrent_index(
      :identities,
      :saml_provider_id,
      where: 'saml_provider_id IS NOT NULL'
    )
  end

  def revert_identities
    remove_column_if_exists(:identities, :saml_provider_id)
    remove_column_if_exists(:identities, :secondary_extern_uid)
  end

  def update_issues
    add_column_if_not_exists(:issues, :service_desk_reply_to, :string)
    add_column_if_not_exists(:issues, :weight, :integer)
  end

  def revert_issues
    remove_column_if_exists(:issues, :service_desk_reply_to)
    remove_column_if_exists(:issues, :weight)
  end

  def update_lists
    add_column_if_not_exists(:lists, :milestone_id, :integer)
    add_column_if_not_exists(:lists, :user_id, :integer)

    add_concurrent_index(:lists, :milestone_id)
    add_concurrent_index(:lists, :user_id)
  end

  def revert_lists
    remove_column_if_exists(:lists, :milestone_id)
    remove_column_if_exists(:lists, :user_id)
  end

  def update_members
    add_column_with_default_if_not_exists(
      :members,
      :ldap,
      :boolean,
      default: false
    )

    add_column_with_default_if_not_exists(
      :members,
      :override,
      :boolean,
      default: false
    )
  end

  def revert_members
    remove_column_if_exists(:members, :ldap)
    remove_column_if_exists(:members, :override)
  end

  def update_merge_requests
    add_column_if_not_exists(:merge_requests, :approvals_before_merge, :integer)
  end

  def revert_merge_requests
    remove_column_if_exists(:merge_requests, :approvals_before_merge)
  end

  def update_notes
    add_column_if_not_exists(:notes, :review_id, :bigint)
    add_concurrent_index(:notes, :review_id)
  end

  def revert_notes
    remove_column_if_exists(:notes, :review_id)
  end

  def update_ci_builds
    add_concurrent_index(
      :ci_builds,
      [:name],
      name: 'index_ci_builds_on_name_for_security_products_values',
      where: "
        (
          (name)::text = ANY (
            ARRAY[
              ('container_scanning'::character varying)::text,
              ('dast'::character varying)::text,
              ('dependency_scanning'::character varying)::text,
              ('license_management'::character varying)::text,
              ('sast'::character varying)::text
            ]
          )
       )"
    )
  end

  def revert_ci_builds
    remove_concurrent_index_by_name(
      :ci_builds,
      'index_ci_builds_on_name_for_security_products_values'
    )
  end

  def update_environments
    return if index_exists?(:environments, :name, name: 'index_environments_on_name_varchar_pattern_ops')

    execute('CREATE INDEX CONCURRENTLY index_environments_on_name_varchar_pattern_ops ON environments (name varchar_pattern_ops);')
  end

  def revert_environments
    remove_concurrent_index_by_name(
      :environments,
      'index_environments_on_name_varchar_pattern_ops'
    )
  end

  def update_namespaces
    change_table(:namespaces) do |t|
      add_missing_columns(t, NAMESPACE_COLUMNS)
    end

    add_column_with_default_if_not_exists(
      :namespaces,
      :ldap_sync_status,
      :string,
      default: 'ready'
    )

    add_column_with_default_if_not_exists(
      :namespaces,
      :membership_lock,
      :boolean,
      default: false,
      allow_null: true
    )

    # When `add_concurrent_index` runs, it for some reason incorrectly
    # determines this index does not exist when it does. To work around this, we
    # check the existence by name ourselves.
    unless index_exists_by_name?(:namespaces, 'index_namespaces_on_custom_project_templates_group_id_and_type')
      add_concurrent_index(
        :namespaces,
        %i[custom_project_templates_group_id type],
        where: "(custom_project_templates_group_id IS NOT NULL)"
      )
    end

    add_concurrent_index(:namespaces, :file_template_project_id)
    add_concurrent_index(:namespaces, :ldap_sync_last_successful_update_at)
    add_concurrent_index(:namespaces, :ldap_sync_last_update_at)
    add_concurrent_index(:namespaces, :plan_id)
    add_concurrent_index(
      :namespaces,
      :trial_ends_on,
      where: "(trial_ends_on IS NOT NULL)"
    )

    unless index_exists_by_name?(:namespaces, 'index_namespaces_on_shared_and_extra_runners_minutes_limit')
      add_concurrent_index(
        :namespaces,
        %i[shared_runners_minutes_limit extra_shared_runners_minutes_limit],
        name: 'index_namespaces_on_shared_and_extra_runners_minutes_limit'
      )
    end
  end

  def revert_namespaces
    remove_columns(:namespaces, NAMESPACE_COLUMNS)
    remove_column_if_exists(:namespaces, :ldap_sync_status)
    remove_column_if_exists(:namespaces, :membership_lock)

    remove_concurrent_index_by_name(
      :namespaces,
      'index_namespaces_on_shared_and_extra_runners_minutes_limit'
    )
  end

  def update_notification_settings
    add_column_if_not_exists(:notification_settings, :new_epic, :boolean)
  end

  def revert_notification_settings
    remove_column_if_exists(:notification_settings, :new_epic)
  end

  def update_project_mirror_data
    change_table(:project_mirror_data) do |t|
      add_missing_columns(t, PROJECT_MIRROR_DATA_COLUMNS)
    end

    add_column_with_default_if_not_exists(
      :project_mirror_data,
      :retry_count,
      :integer,
      default: 0
    )

    add_concurrent_index(:project_mirror_data, :last_successful_update_at)

    add_concurrent_index(
      :project_mirror_data,
      %i[next_execution_timestamp retry_count],
      name: 'index_mirror_data_on_next_execution_and_retry_count'
    )
  end

  def revert_project_mirror_data
    remove_columns(:project_mirror_data, PROJECT_MIRROR_DATA_COLUMNS)

    remove_concurrent_index_by_name(
      :project_mirror_data,
      'index_mirror_data_on_next_execution_and_retry_count'
    )

    remove_column_if_exists(:project_statistics, :retry_count)
  end

  def update_project_statistics
    add_column_with_default_if_not_exists(
      :project_statistics,
      :shared_runners_seconds,
      :bigint,
      default: 0
    )

    add_column_if_not_exists(
      :project_statistics,
      :shared_runners_seconds_last_reset,
      :datetime
    )
  end

  def revert_project_statistics
    remove_column_if_exists(:project_statistics, :shared_runners_seconds)

    remove_column_if_exists(
      :project_statistics,
      :shared_runners_seconds_last_reset
    )
  end

  def update_projects
    change_table(:projects) do |t|
      add_missing_columns(t, PROJECTS_COLUMNS)
    end

    change_column_null(:projects, :merge_requests_rebase_enabled, true)

    add_column_with_default_if_not_exists(
      :projects,
      :mirror,
      :boolean,
      default: false
    )

    add_column_with_default_if_not_exists(
      :projects,
      :mirror_trigger_builds,
      :boolean,
      default: false
    )

    add_column_with_default_if_not_exists(
      :projects,
      :reset_approvals_on_push,
      :boolean,
      default: true,
      allow_null: true
    )

    add_column_with_default_if_not_exists(
      :projects,
      :service_desk_enabled,
      :boolean,
      default: true,
      allow_null: true
    )

    add_column_with_default_if_not_exists(
      :projects,
      :approvals_before_merge,
      :integer,
      default: 0
    )

    add_concurrent_index(
      :projects,
      %i[archived pending_delete merge_requests_require_code_owner_approval],
      name: 'projects_requiring_code_owner_approval',
      where: '((pending_delete = false) AND (archived = false) AND (merge_requests_require_code_owner_approval = true))'
    )

    add_concurrent_index(
      :projects,
      %i[id repository_storage last_repository_updated_at],
      name: 'idx_projects_on_repository_storage_last_repository_updated_at'
    )

    add_concurrent_index(
      :projects,
      :id,
      name: 'index_projects_on_mirror_and_mirror_trigger_builds_both_true',
      where: '((mirror IS TRUE) AND (mirror_trigger_builds IS TRUE))'
    )

    add_concurrent_index(:projects, :mirror_last_successful_update_at)
  end

  def revert_projects
    remove_columns(:projects, PROJECTS_COLUMNS)

    Project
      .where(merge_requests_rebase_enabled: nil)
      .update_all(merge_requests_rebase_enabled: false)

    change_column_null(:projects, :merge_requests_rebase_enabled, false)

    remove_column_if_exists(:projects, :mirror)
    remove_column_if_exists(:projects, :mirror_trigger_builds)
    remove_column_if_exists(:projects, :reset_approvals_on_push)
    remove_column_if_exists(:projects, :service_desk_enabled)
    remove_column_if_exists(:projects, :approvals_before_merge)

    remove_concurrent_index_by_name(
      :projects,
      'projects_requiring_code_owner_approval'
    )

    remove_concurrent_index_by_name(
      :projects,
      'idx_projects_on_repository_storage_last_repository_updated_at'
    )

    remove_concurrent_index_by_name(
      :projects,
      'index_projects_on_mirror_and_mirror_trigger_builds_both_true'
    )
  end

  def update_protected_branch_merge_access_levels
    change_column_null(:protected_branch_merge_access_levels, :access_level, true)

    add_column_if_not_exists(
      :protected_branch_merge_access_levels,
      :group_id,
      :integer
    )

    add_column_if_not_exists(
      :protected_branch_merge_access_levels,
      :user_id,
      :integer
    )

    add_concurrent_index(:protected_branch_merge_access_levels, :group_id)
    add_concurrent_index(:protected_branch_merge_access_levels, :user_id)
  end

  def revert_protected_branch_merge_access_levels
    ProtectedBranchMergeAccessLevels
      .where(access_level: nil)
      .update_all(access_level: false)

    change_column_null(
      :protected_branch_merge_access_levels,
      :access_level,
      false
    )

    remove_column_if_exists(:protected_branch_merge_access_levels, :group_id)
    remove_column_if_exists(:protected_branch_merge_access_levels, :user_id)
  end

  def update_protected_branch_push_access_levels
    change_column_null(
      :protected_branch_push_access_levels,
      :access_level,
      true
    )

    add_column_if_not_exists(
      :protected_branch_push_access_levels,
      :group_id,
      :integer
    )

    add_column_if_not_exists(
      :protected_branch_push_access_levels,
      :user_id,
      :integer
    )

    add_concurrent_index(:protected_branch_push_access_levels, :group_id)
    add_concurrent_index(:protected_branch_push_access_levels, :user_id)
  end

  def revert_protected_branch_push_access_levels
    ProtectedBranchPushAccessLevels
      .where(access_level: nil)
      .update_all(access_level: false)

    change_column_null(
      :protected_branch_push_access_levels,
      :access_level,
      false
    )

    remove_column_if_exists(:protected_branch_push_access_levels, :group_id)
    remove_column_if_exists(:protected_branch_push_access_levels, :user_id)
  end

  def update_resource_label_events
    add_column_if_not_exists(:resource_label_events, :epic_id, :integer)
    add_concurrent_index(:resource_label_events, :epic_id)
  end

  def revert_resource_label_events
    remove_column_if_exists(:resource_label_events, :epic_id)
  end

  def update_user_preferences
    add_column_with_default_if_not_exists(
      :user_preferences,
      :epic_notes_filter,
      :integer,
      default: 0,
      limit: 2
    )

    add_column_if_not_exists(:user_preferences, :epics_sort, :string)
    add_column_if_not_exists(:user_preferences, :roadmap_epics_state, :integer)
    add_column_if_not_exists(:user_preferences, :roadmaps_sort, :string)
  end

  def revert_user_preferences
    remove_column_if_exists(:user_preferences, :epic_notes_filter)
    remove_column_if_exists(:user_preferences, :epics_sort)
    remove_column_if_exists(:user_preferences, :roadmap_epics_state)
    remove_column_if_exists(:user_preferences, :roadmaps_sort)
  end

  def update_users
    add_column_with_default_if_not_exists(
      :users,
      :auditor,
      :boolean,
      default: false
    )

    change_table(:users) do |t|
      add_missing_columns(t, USERS_COLUMNS)
    end

    add_concurrent_index(:users, :group_view)
    add_concurrent_index(:users, :managing_group_id)
    add_concurrent_index(:users, :support_bot)
    add_concurrent_index(:users, :bot_type)

    add_concurrent_index(
      :users,
      :state,
      name: 'index_users_on_state_and_internal_attrs',
      where: '((ghost <> true) AND (support_bot <> true))'
    )

    internal_index = 'index_users_on_state_and_internal'

    remove_concurrent_index(:users, :state, name: internal_index)

    add_concurrent_index(
      :users,
      :state,
      name: internal_index,
      where: '((ghost <> true) AND (bot_type IS NULL))'
    )
  end

  def revert_users
    remove_column_if_exists(:users, :auditor)
    remove_columns(:users, USERS_COLUMNS)

    remove_concurrent_index_by_name(
      :users,
      'index_users_on_state_and_internal_attrs'
    )

    internal_index = 'index_users_on_state_and_internal'

    remove_concurrent_index(:users, :state, name: internal_index)
    add_concurrent_index(:users, :state, name: internal_index)
  end

  def update_web_hooks
    add_column_if_not_exists(:web_hooks, :group_id, :integer)
  end

  def revert_web_hooks
    remove_column_if_exists(:web_hooks, :group_id)
  end

  def update_geo_nodes
    add_column_if_not_exists(:geo_nodes, :internal_url, :string)
  end

  def revert_geo_nodes
    remove_column_if_exists(:geo_nodes, :internal_url)
  end

  # Some users may have upgraded to EE at some point but downgraded to
  # CE v11.11.3.  As a result, their EE tables may not be in the right
  # state. Here we check for these such cases and attempt to guide the
  # user into recovering from this state by upgrading to v11.11.3 EE
  # before installing v12.0.0 CE.
  def check_schema!
    # The following cases will fail later when this migration attempts
    # to add a foreign key for non-existent columns.
    columns_to_check = [
      [:epics, :parent_id], # Added in GitLab 11.7
      [:geo_event_log, :cache_invalidation_event_id], # Added in GitLab 11.4
      [:vulnerability_feedback, :merge_request_id] # Added in GitLab 11.9
    ].freeze

    columns_to_check.each do |table, column|
      check_ee_columns!(table, column)
    end
  end

  def check_ee_columns!(table, column)
    return unless table_exists?(table)
    return if column_exists?(table, column)

    raise_ee_migration_error!(table, column)
  end

  def raise_ee_migration_error!(table, column)
    message = "Your database is missing the '#{column}' column from the '#{table}' table that is present for GitLab EE."

    message +=
      if ::Gitlab.ee?
        "\nUpgrade your GitLab instance to 11.11.3 EE first!"
      else
        <<~MSG

          Even though it looks like you're running a CE installation, it appears
          you may have installed GitLab EE at some point. To migrate to GitLab 12.0:

          1. Install GitLab 11.11.3 EE
          2. Install GitLab 12.0.x CE
        MSG
      end

    raise StandardError, message
  end

  def create_missing_tables
    create_table_if_not_exists "approval_merge_request_rule_sources", id: :bigserial do |t|
      t.bigint "approval_merge_request_rule_id", null: false
      t.bigint "approval_project_rule_id", null: false
      t.index %w[approval_merge_request_rule_id], name: "index_approval_merge_request_rule_sources_1", unique: true, using: :btree
      t.index %w[approval_project_rule_id], name: "index_approval_merge_request_rule_sources_2", using: :btree
    end

    create_table_if_not_exists "approval_merge_request_rules", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "merge_request_id", null: false
      t.integer "approvals_required", limit: 2, default: 0, null: false
      t.boolean "code_owner", default: false, null: false
      t.string "name", null: false
      t.index %w[merge_request_id code_owner name], name: "approval_rule_name_index_for_code_owners", unique: true, where: "(code_owner = true)", using: :btree
      t.index %w[merge_request_id code_owner], name: "index_approval_merge_request_rules_1", using: :btree
    end

    create_table_if_not_exists "approval_merge_request_rules_approved_approvers", id: :bigserial do |t|
      t.bigint "approval_merge_request_rule_id", null: false
      t.integer "user_id", null: false
      t.index %w[approval_merge_request_rule_id user_id], name: "index_approval_merge_request_rules_approved_approvers_1", unique: true, using: :btree
      t.index %w[user_id], name: "index_approval_merge_request_rules_approved_approvers_2", using: :btree
    end

    create_table_if_not_exists "approval_merge_request_rules_groups", id: :bigserial do |t|
      t.bigint "approval_merge_request_rule_id", null: false
      t.integer "group_id", null: false
      t.index %w[approval_merge_request_rule_id group_id], name: "index_approval_merge_request_rules_groups_1", unique: true, using: :btree
      t.index %w[group_id], name: "index_approval_merge_request_rules_groups_2", using: :btree
    end

    create_table_if_not_exists "approval_merge_request_rules_users", id: :bigserial do |t|
      t.bigint "approval_merge_request_rule_id", null: false
      t.integer "user_id", null: false
      t.index %w[approval_merge_request_rule_id user_id], name: "index_approval_merge_request_rules_users_1", unique: true, using: :btree
      t.index %w[user_id], name: "index_approval_merge_request_rules_users_2", using: :btree
    end

    create_table_if_not_exists "approval_project_rules", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "project_id", null: false
      t.integer "approvals_required", limit: 2, default: 0, null: false
      t.string "name", null: false
      t.index %w[project_id], name: "index_approval_project_rules_on_project_id", using: :btree
    end

    create_table_if_not_exists "approval_project_rules_groups", id: :bigserial do |t|
      t.bigint "approval_project_rule_id", null: false
      t.integer "group_id", null: false
      t.index %w[approval_project_rule_id group_id], name: "index_approval_project_rules_groups_1", unique: true, using: :btree
      t.index %w[group_id], name: "index_approval_project_rules_groups_2", using: :btree
    end

    create_table_if_not_exists "approval_project_rules_users", id: :bigserial do |t|
      t.bigint "approval_project_rule_id", null: false
      t.integer "user_id", null: false
      t.index %w[approval_project_rule_id user_id], name: "index_approval_project_rules_users_1", unique: true, using: :btree
      t.index %w[user_id], name: "index_approval_project_rules_users_2", using: :btree
    end

    create_table_if_not_exists "approvals" do |t|
      t.integer "merge_request_id", null: false
      t.integer "user_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index %w[merge_request_id], name: "index_approvals_on_merge_request_id", using: :btree
    end

    create_table_if_not_exists "approver_groups" do |t|
      t.integer "target_id", null: false
      t.string "target_type", null: false
      t.integer "group_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index %w[group_id], name: "index_approver_groups_on_group_id", using: :btree
      t.index %w[target_id target_type], name: "index_approver_groups_on_target_id_and_target_type", using: :btree
    end

    create_table_if_not_exists "approvers" do |t|
      t.integer "target_id", null: false
      t.string "target_type"
      t.integer "user_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index %w[target_id target_type], name: "index_approvers_on_target_id_and_target_type", using: :btree
      t.index %w[user_id], name: "index_approvers_on_user_id", using: :btree
    end

    create_table_if_not_exists "board_assignees" do |t|
      t.integer "board_id", null: false
      t.integer "assignee_id", null: false
      t.index %w[assignee_id], name: "index_board_assignees_on_assignee_id", using: :btree
      t.index %w[board_id assignee_id], name: "index_board_assignees_on_board_id_and_assignee_id", unique: true, using: :btree
    end

    create_table_if_not_exists "board_labels" do |t|
      t.integer "board_id", null: false
      t.integer "label_id", null: false
      t.index %w[board_id label_id], name: "index_board_labels_on_board_id_and_label_id", unique: true, using: :btree
      t.index %w[label_id], name: "index_board_labels_on_label_id", using: :btree
    end

    create_table_if_not_exists "ci_sources_pipelines" do |t|
      t.integer "project_id"
      t.integer "pipeline_id"
      t.integer "source_project_id"
      t.integer "source_job_id"
      t.integer "source_pipeline_id"
      t.index ["pipeline_id"], name: "index_ci_sources_pipelines_on_pipeline_id", using: :btree
      t.index ["project_id"], name: "index_ci_sources_pipelines_on_project_id", using: :btree
      t.index ["source_job_id"], name: "index_ci_sources_pipelines_on_source_job_id", using: :btree
      t.index ["source_pipeline_id"], name: "index_ci_sources_pipelines_on_source_pipeline_id", using: :btree
      t.index ["source_project_id"], name: "index_ci_sources_pipelines_on_source_project_id", using: :btree
    end

    create_table_if_not_exists "design_management_designs", id: :bigserial, force: :cascade do |t|
      t.integer "project_id", null: false
      t.integer "issue_id", null: false
      t.string "filename", null: false
      t.index %w[issue_id filename], name: "index_design_management_designs_on_issue_id_and_filename", unique: true, using: :btree
      t.index ["project_id"], name: "index_design_management_designs_on_project_id", using: :btree
    end

    create_table_if_not_exists "design_management_designs_versions", id: false, force: :cascade do |t|
      t.bigint "design_id", null: false
      t.bigint "version_id", null: false
      t.index %w[design_id version_id], name: "design_management_designs_versions_uniqueness", unique: true, using: :btree
      t.index ["design_id"], name: "index_design_management_designs_versions_on_design_id", using: :btree
      t.index ["version_id"], name: "index_design_management_designs_versions_on_version_id", using: :btree
    end

    create_table_if_not_exists "design_management_versions", id: :bigserial, force: :cascade do |t|
      t.binary "sha", null: false
      t.index ["sha"], name: "index_design_management_versions_on_sha", unique: true, using: :btree
    end

    create_table_if_not_exists "draft_notes", id: :bigserial do |t|
      t.integer "merge_request_id", null: false
      t.integer "author_id", null: false
      t.boolean "resolve_discussion", default: false, null: false
      t.string "discussion_id"
      t.text "note", null: false
      t.text "position"
      t.text "original_position"
      t.text "change_position"
      t.index ["author_id"], name: "index_draft_notes_on_author_id", using: :btree
      t.index ["discussion_id"], name: "index_draft_notes_on_discussion_id", using: :btree
      t.index ["merge_request_id"], name: "index_draft_notes_on_merge_request_id", using: :btree
    end

    create_table_if_not_exists "elasticsearch_indexed_namespaces", id: false do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "namespace_id"
      t.index ["namespace_id"], name: "index_elasticsearch_indexed_namespaces_on_namespace_id", unique: true, using: :btree
    end

    create_table_if_not_exists "elasticsearch_indexed_projects", id: false do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "project_id"
      t.index ["project_id"], name: "index_elasticsearch_indexed_projects_on_project_id", unique: true, using: :btree
    end

    create_table_if_not_exists "epic_issues" do |t|
      t.integer "epic_id", null: false
      t.integer "issue_id", null: false
      t.integer "relative_position", default: 1073741823, null: false
      t.index ["epic_id"], name: "index_epic_issues_on_epic_id", using: :btree
      t.index ["issue_id"], name: "index_epic_issues_on_issue_id", unique: true, using: :btree
    end

    create_table_if_not_exists "epic_metrics" do |t|
      t.integer "epic_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["epic_id"], name: "index_epic_metrics", using: :btree
    end

    create_table_if_not_exists "epics" do |t|
      t.integer "milestone_id"
      t.integer "group_id", null: false
      t.integer "author_id", null: false
      t.integer "assignee_id"
      t.integer "iid", null: false
      t.integer "cached_markdown_version"
      t.integer "updated_by_id"
      t.integer "last_edited_by_id"
      t.integer "lock_version"
      t.date "start_date"
      t.date "end_date"
      t.datetime "last_edited_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "title", null: false
      t.string "title_html", null: false
      t.text "description"
      t.text "description_html"
      t.integer "start_date_sourcing_milestone_id"
      t.integer "due_date_sourcing_milestone_id"
      t.date "start_date_fixed"
      t.date "due_date_fixed"
      t.boolean "start_date_is_fixed"
      t.boolean "due_date_is_fixed"
      t.integer "state", limit: 2, default: 1, null: false
      t.integer "closed_by_id"
      t.datetime "closed_at"
      t.integer "parent_id"
      t.integer "relative_position"
      t.index ["assignee_id"], name: "index_epics_on_assignee_id", using: :btree
      t.index ["author_id"], name: "index_epics_on_author_id", using: :btree
      t.index ["closed_by_id"], name: "index_epics_on_closed_by_id", using: :btree
      t.index ["end_date"], name: "index_epics_on_end_date", using: :btree
      t.index ["group_id"], name: "index_epics_on_group_id", using: :btree
      t.index ["iid"], name: "index_epics_on_iid", using: :btree
      t.index ["milestone_id"], name: "index_milestone", using: :btree
      t.index ["parent_id"], name: "index_epics_on_parent_id", using: :btree
      t.index ["start_date"], name: "index_epics_on_start_date", using: :btree
    end

    create_table_if_not_exists "geo_cache_invalidation_events", id: :bigserial do |t|
      t.string "key", null: false
    end

    create_table_if_not_exists "geo_event_log", id: :bigserial do |t|
      t.datetime "created_at", null: false
      t.bigint "repository_updated_event_id"
      t.bigint "repository_deleted_event_id"
      t.bigint "repository_renamed_event_id"
      t.bigint "repositories_changed_event_id"
      t.bigint "repository_created_event_id"
      t.bigint "hashed_storage_migrated_event_id"
      t.bigint "lfs_object_deleted_event_id"
      t.bigint "hashed_storage_attachments_event_id"
      t.bigint "upload_deleted_event_id"
      t.bigint "job_artifact_deleted_event_id"
      t.bigint "reset_checksum_event_id"
      t.bigint "cache_invalidation_event_id"
      t.index ["cache_invalidation_event_id"], name: "index_geo_event_log_on_cache_invalidation_event_id", where: "(cache_invalidation_event_id IS NOT NULL)", using: :btree
      t.index ["hashed_storage_attachments_event_id"], name: "index_geo_event_log_on_hashed_storage_attachments_event_id", where: "(hashed_storage_attachments_event_id IS NOT NULL)", using: :btree
      t.index ["hashed_storage_migrated_event_id"], name: "index_geo_event_log_on_hashed_storage_migrated_event_id", where: "(hashed_storage_migrated_event_id IS NOT NULL)", using: :btree
      t.index ["job_artifact_deleted_event_id"], name: "index_geo_event_log_on_job_artifact_deleted_event_id", where: "(job_artifact_deleted_event_id IS NOT NULL)", using: :btree
      t.index ["lfs_object_deleted_event_id"], name: "index_geo_event_log_on_lfs_object_deleted_event_id", where: "(lfs_object_deleted_event_id IS NOT NULL)", using: :btree
      t.index ["repositories_changed_event_id"], name: "index_geo_event_log_on_repositories_changed_event_id", where: "(repositories_changed_event_id IS NOT NULL)", using: :btree
      t.index ["repository_created_event_id"], name: "index_geo_event_log_on_repository_created_event_id", where: "(repository_created_event_id IS NOT NULL)", using: :btree
      t.index ["repository_deleted_event_id"], name: "index_geo_event_log_on_repository_deleted_event_id", where: "(repository_deleted_event_id IS NOT NULL)", using: :btree
      t.index ["repository_renamed_event_id"], name: "index_geo_event_log_on_repository_renamed_event_id", where: "(repository_renamed_event_id IS NOT NULL)", using: :btree
      t.index ["repository_updated_event_id"], name: "index_geo_event_log_on_repository_updated_event_id", where: "(repository_updated_event_id IS NOT NULL)", using: :btree
      t.index ["reset_checksum_event_id"], name: "index_geo_event_log_on_reset_checksum_event_id", where: "(reset_checksum_event_id IS NOT NULL)", using: :btree
      t.index ["upload_deleted_event_id"], name: "index_geo_event_log_on_upload_deleted_event_id", where: "(upload_deleted_event_id IS NOT NULL)", using: :btree
    end

    create_table_if_not_exists "geo_hashed_storage_attachments_events", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.text "old_attachments_path", null: false
      t.text "new_attachments_path", null: false
      t.index ["project_id"], name: "index_geo_hashed_storage_attachments_events_on_project_id", using: :btree
    end

    create_table_if_not_exists "geo_hashed_storage_migrated_events", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.text "repository_storage_name", null: false
      t.text "old_disk_path", null: false
      t.text "new_disk_path", null: false
      t.text "old_wiki_disk_path", null: false
      t.text "new_wiki_disk_path", null: false
      t.integer "old_storage_version", limit: 2
      t.integer "new_storage_version", limit: 2, null: false
      t.index ["project_id"], name: "index_geo_hashed_storage_migrated_events_on_project_id", using: :btree
    end

    create_table_if_not_exists "geo_job_artifact_deleted_events", id: :bigserial do |t|
      t.integer "job_artifact_id", null: false
      t.string "file_path", null: false
      t.index ["job_artifact_id"], name: "index_geo_job_artifact_deleted_events_on_job_artifact_id", using: :btree
    end

    create_table_if_not_exists "geo_lfs_object_deleted_events", id: :bigserial do |t|
      t.integer "lfs_object_id", null: false
      t.string "oid", null: false
      t.string "file_path", null: false
      t.index ["lfs_object_id"], name: "index_geo_lfs_object_deleted_events_on_lfs_object_id", using: :btree
    end

    create_table_if_not_exists "geo_node_namespace_links" do |t|
      t.integer "geo_node_id", null: false
      t.integer "namespace_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index %w[geo_node_id namespace_id], name: "index_geo_node_namespace_links_on_geo_node_id_and_namespace_id", unique: true, using: :btree
      t.index ["geo_node_id"], name: "index_geo_node_namespace_links_on_geo_node_id", using: :btree
      t.index ["namespace_id"], name: "index_geo_node_namespace_links_on_namespace_id", using: :btree
    end

    create_table_if_not_exists "geo_node_statuses" do |t|
      t.integer "geo_node_id", null: false
      t.integer "db_replication_lag_seconds"
      t.integer "repositories_synced_count"
      t.integer "repositories_failed_count"
      t.integer "lfs_objects_count"
      t.integer "lfs_objects_synced_count"
      t.integer "lfs_objects_failed_count"
      t.integer "attachments_count"
      t.integer "attachments_synced_count"
      t.integer "attachments_failed_count"
      t.integer "last_event_id"
      t.datetime "last_event_date"
      t.integer "cursor_last_event_id"
      t.datetime "cursor_last_event_date"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.datetime "last_successful_status_check_at"
      t.string "status_message"
      t.integer "replication_slots_count"
      t.integer "replication_slots_used_count"
      t.bigint "replication_slots_max_retained_wal_bytes"
      t.integer "wikis_synced_count"
      t.integer "wikis_failed_count"
      t.integer "job_artifacts_count"
      t.integer "job_artifacts_synced_count"
      t.integer "job_artifacts_failed_count"
      t.string "version"
      t.string "revision"
      t.integer "repositories_verified_count"
      t.integer "repositories_verification_failed_count"
      t.integer "wikis_verified_count"
      t.integer "wikis_verification_failed_count"
      t.integer "lfs_objects_synced_missing_on_primary_count"
      t.integer "job_artifacts_synced_missing_on_primary_count"
      t.integer "attachments_synced_missing_on_primary_count"
      t.integer "repositories_checksummed_count"
      t.integer "repositories_checksum_failed_count"
      t.integer "repositories_checksum_mismatch_count"
      t.integer "wikis_checksummed_count"
      t.integer "wikis_checksum_failed_count"
      t.integer "wikis_checksum_mismatch_count"
      t.binary "storage_configuration_digest"
      t.integer "repositories_retrying_verification_count"
      t.integer "wikis_retrying_verification_count"
      t.integer "projects_count"
      t.index ["geo_node_id"], name: "index_geo_node_statuses_on_geo_node_id", unique: true, using: :btree
    end

    create_table_if_not_exists "geo_nodes" do |t|
      t.boolean "primary"
      t.integer "oauth_application_id"
      t.boolean "enabled", default: true, null: false
      t.string "access_key"
      t.string "encrypted_secret_access_key"
      t.string "encrypted_secret_access_key_iv"
      t.string "clone_url_prefix"
      t.integer "files_max_capacity", default: 10, null: false
      t.integer "repos_max_capacity", default: 25, null: false
      t.string "url", null: false
      t.string "selective_sync_type"
      t.text "selective_sync_shards"
      t.integer "verification_max_capacity", default: 100, null: false
      t.integer "minimum_reverification_interval", default: 7, null: false
      t.string "alternate_url"
      t.index ["access_key"], name: "index_geo_nodes_on_access_key", using: :btree
      t.index ["primary"], name: "index_geo_nodes_on_primary", using: :btree
      t.index ["url"], name: "index_geo_nodes_on_url", unique: true, using: :btree
    end

    create_table_if_not_exists "geo_repositories_changed_events", id: :bigserial do |t|
      t.integer "geo_node_id", null: false
      t.index ["geo_node_id"], name: "index_geo_repositories_changed_events_on_geo_node_id", using: :btree
    end

    create_table_if_not_exists "geo_repository_created_events", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.text "repository_storage_name", null: false
      t.text "repo_path", null: false
      t.text "wiki_path"
      t.text "project_name", null: false
      t.index ["project_id"], name: "index_geo_repository_created_events_on_project_id", using: :btree
    end

    create_table_if_not_exists "geo_repository_deleted_events", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.text "repository_storage_name", null: false
      t.text "deleted_path", null: false
      t.text "deleted_wiki_path"
      t.text "deleted_project_name", null: false
      t.index ["project_id"], name: "index_geo_repository_deleted_events_on_project_id", using: :btree
    end

    create_table_if_not_exists "geo_repository_renamed_events", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.text "repository_storage_name", null: false
      t.text "old_path_with_namespace", null: false
      t.text "new_path_with_namespace", null: false
      t.text "old_wiki_path_with_namespace", null: false
      t.text "new_wiki_path_with_namespace", null: false
      t.text "old_path", null: false
      t.text "new_path", null: false
      t.index ["project_id"], name: "index_geo_repository_renamed_events_on_project_id", using: :btree
    end

    create_table_if_not_exists "geo_repository_updated_events", id: :bigserial do |t|
      t.integer "branches_affected", null: false
      t.integer "tags_affected", null: false
      t.integer "project_id", null: false
      t.integer "source", limit: 2, null: false
      t.boolean "new_branch", default: false, null: false
      t.boolean "remove_branch", default: false, null: false
      t.text "ref"
      t.index ["project_id"], name: "index_geo_repository_updated_events_on_project_id", using: :btree
      t.index ["source"], name: "index_geo_repository_updated_events_on_source", using: :btree
    end

    create_table_if_not_exists "geo_reset_checksum_events", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.index ["project_id"], name: "index_geo_reset_checksum_events_on_project_id", using: :btree
    end

    create_table_if_not_exists "geo_upload_deleted_events", id: :bigserial do |t|
      t.integer "upload_id", null: false
      t.string "file_path", null: false
      t.integer "model_id", null: false
      t.string "model_type", null: false
      t.string "uploader", null: false
      t.index ["upload_id"], name: "index_geo_upload_deleted_events_on_upload_id", using: :btree
    end

    create_table_if_not_exists "gitlab_subscriptions", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.date "start_date"
      t.date "end_date"
      t.date "trial_ends_on"
      t.integer "namespace_id"
      t.integer "hosted_plan_id"
      t.integer "max_seats_used", default: 0
      t.integer "seats", default: 0
      t.boolean "trial", default: false
      t.index ["hosted_plan_id"], name: "index_gitlab_subscriptions_on_hosted_plan_id", using: :btree
      t.index ["namespace_id"], name: "index_gitlab_subscriptions_on_namespace_id", unique: true, using: :btree
    end

    create_table_if_not_exists "historical_data" do |t|
      t.date "date", null: false
      t.integer "active_user_count"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table_if_not_exists "index_statuses" do |t|
      t.integer "project_id", null: false
      t.datetime "indexed_at"
      t.text "note"
      t.string "last_commit"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["project_id"], name: "index_index_statuses_on_project_id", unique: true, using: :btree
    end

    create_table_if_not_exists "insights" do |t|
      t.integer "namespace_id", null: false
      t.integer "project_id", null: false
      t.index ["namespace_id"], name: "index_insights_on_namespace_id", using: :btree
      t.index ["project_id"], name: "index_insights_on_project_id", using: :btree
    end

    create_table_if_not_exists "issue_links" do |t|
      t.integer "source_id", null: false
      t.integer "target_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index %w[source_id target_id], name: "index_issue_links_on_source_id_and_target_id", unique: true, using: :btree
      t.index ["source_id"], name: "index_issue_links_on_source_id", using: :btree
      t.index ["target_id"], name: "index_issue_links_on_target_id", using: :btree
    end

    create_table_if_not_exists "jira_connect_installations", id: :bigserial do |t|
      t.string "client_key"
      t.string "encrypted_shared_secret"
      t.string "encrypted_shared_secret_iv"
      t.string "base_url"
      t.index ["client_key"], name: "index_jira_connect_installations_on_client_key", unique: true, using: :btree
    end

    create_table_if_not_exists "jira_connect_subscriptions", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.bigint "jira_connect_installation_id", null: false
      t.integer "namespace_id", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.index %w[jira_connect_installation_id namespace_id], name: "idx_jira_connect_subscriptions_on_installation_id_namespace_id", unique: true, using: :btree
      t.index ["jira_connect_installation_id"], name: "idx_jira_connect_subscriptions_on_installation_id", using: :btree
      t.index ["namespace_id"], name: "index_jira_connect_subscriptions_on_namespace_id", using: :btree
    end

    create_table_if_not_exists "ldap_group_links" do |t|
      t.string "cn"
      t.integer "group_access", null: false
      t.integer "group_id", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "provider"
      t.string "filter"
    end

    create_table_if_not_exists "licenses" do |t|
      t.text "data", null: false
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table_if_not_exists "namespace_statistics" do |t|
      t.integer "namespace_id", null: false
      t.integer "shared_runners_seconds", default: 0, null: false
      t.datetime "shared_runners_seconds_last_reset"
      t.index ["namespace_id"], name: "index_namespace_statistics_on_namespace_id", unique: true, using: :btree
    end

    create_table_if_not_exists "operations_feature_flag_scopes", id: :bigserial do |t|
      t.bigint "feature_flag_id", null: false
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.boolean "active", null: false
      t.string "environment_scope", default: "*", null: false
      t.index %w[feature_flag_id environment_scope], name: "index_feature_flag_scopes_on_flag_id_and_environment_scope", unique: true, using: :btree
    end

    create_table_if_not_exists "operations_feature_flags", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.boolean "active", null: false
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.string "name", null: false
      t.text "description"
      t.index %w[project_id name], name: "index_operations_feature_flags_on_project_id_and_name", unique: true, using: :btree
    end

    create_table_if_not_exists "operations_feature_flags_clients", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.string "token", null: false
      t.index %w[project_id token], name: "index_operations_feature_flags_clients_on_project_id_and_token", unique: true, using: :btree
    end

    create_table_if_not_exists "packages_maven_metadata", id: :bigserial do |t|
      t.bigint "package_id", null: false
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.string "app_group", null: false
      t.string "app_name", null: false
      t.string "app_version"
      t.string "path", limit: 512, null: false
      t.index %w[package_id path], name: "index_packages_maven_metadata_on_package_id_and_path", using: :btree
    end

    create_table_if_not_exists "packages_package_files", id: :bigserial do |t|
      t.bigint "package_id", null: false
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.bigint "size"
      t.integer "file_type"
      t.integer "file_store"
      t.binary "file_md5"
      t.binary "file_sha1"
      t.string "file_name", null: false
      t.text "file", null: false
      t.index %w[package_id file_name], name: "index_packages_package_files_on_package_id_and_file_name", using: :btree
    end

    create_table_if_not_exists "packages_packages", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.string "name", null: false
      t.string "version"
      t.integer "package_type", limit: 2, null: false
      t.index ["project_id"], name: "index_packages_packages_on_project_id", using: :btree
    end

    create_table_if_not_exists "path_locks" do |t|
      t.string "path", null: false
      t.integer "project_id"
      t.integer "user_id"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["path"], name: "index_path_locks_on_path", using: :btree
      t.index ["project_id"], name: "index_path_locks_on_project_id", using: :btree
      t.index ["user_id"], name: "index_path_locks_on_user_id", using: :btree
    end

    create_table_if_not_exists "plans" do |t|
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "name"
      t.string "title"
      t.integer "active_pipelines_limit"
      t.integer "pipeline_size_limit"
      t.index ["name"], name: "index_plans_on_name", using: :btree
    end

    create_table_if_not_exists "project_alerting_settings", primary_key: "project_id", id: :integer do |t|
      t.string "encrypted_token", null: false
      t.string "encrypted_token_iv", null: false
    end

    create_table_if_not_exists "project_feature_usages", primary_key: "project_id", id: :integer do |t|
      t.datetime "jira_dvcs_cloud_last_sync_at"
      t.datetime "jira_dvcs_server_last_sync_at"
      t.index %w[jira_dvcs_cloud_last_sync_at project_id], name: "idx_proj_feat_usg_on_jira_dvcs_cloud_last_sync_at_and_proj_id", where: "(jira_dvcs_cloud_last_sync_at IS NOT NULL)", using: :btree
      t.index %w[jira_dvcs_server_last_sync_at project_id], name: "idx_proj_feat_usg_on_jira_dvcs_server_last_sync_at_and_proj_id", where: "(jira_dvcs_server_last_sync_at IS NOT NULL)", using: :btree
      t.index ["project_id"], name: "index_project_feature_usages_on_project_id", using: :btree
    end

    create_table_if_not_exists "project_incident_management_settings", primary_key: "project_id", id: :integer do |t|
      t.boolean "create_issue", default: false, null: false
      t.boolean "send_email", default: true, null: false
      t.text "issue_template_key"
    end

    create_table_if_not_exists "project_repository_states" do |t|
      t.integer "project_id", null: false
      t.binary "repository_verification_checksum"
      t.binary "wiki_verification_checksum"
      t.string "last_repository_verification_failure"
      t.string "last_wiki_verification_failure"
      t.datetime_with_timezone "repository_retry_at"
      t.datetime_with_timezone "wiki_retry_at"
      t.integer "repository_retry_count"
      t.integer "wiki_retry_count"
      t.datetime_with_timezone "last_repository_verification_ran_at"
      t.datetime_with_timezone "last_wiki_verification_ran_at"
      t.index ["last_repository_verification_failure"], name: "idx_repository_states_on_repository_failure_partial", where: "(last_repository_verification_failure IS NOT NULL)", using: :btree
      t.index ["last_wiki_verification_failure"], name: "idx_repository_states_on_wiki_failure_partial", where: "(last_wiki_verification_failure IS NOT NULL)", using: :btree
      t.index %w[project_id last_repository_verification_ran_at], name: "idx_repository_states_on_last_repository_verification_ran_at", where: "((repository_verification_checksum IS NOT NULL) AND (last_repository_verification_failure IS NULL))", using: :btree
      t.index %w[project_id last_wiki_verification_ran_at], name: "idx_repository_states_on_last_wiki_verification_ran_at", where: "((wiki_verification_checksum IS NOT NULL) AND (last_wiki_verification_failure IS NULL))", using: :btree
      t.index ["project_id"], name: "idx_repository_states_outdated_checksums", where: "(((repository_verification_checksum IS NULL) AND (last_repository_verification_failure IS NULL)) OR ((wiki_verification_checksum IS NULL) AND (last_wiki_verification_failure IS NULL)))", using: :btree
      t.index ["project_id"], name: "index_project_repository_states_on_project_id", unique: true, using: :btree
    end

    create_table_if_not_exists "project_tracing_settings", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "project_id", null: false
      t.string "external_url", null: false
      t.index ["project_id"], name: "index_project_tracing_settings_on_project_id", unique: true, using: :btree
    end

    create_table_if_not_exists "prometheus_alert_events", id: :bigserial do |t|
      t.integer "project_id", null: false
      t.integer "prometheus_alert_id", null: false
      t.datetime_with_timezone "started_at", null: false
      t.datetime_with_timezone "ended_at"
      t.integer "status", limit: 2
      t.string "payload_key"
      t.index %w[project_id status], name: "index_prometheus_alert_events_on_project_id_and_status", using: :btree
      t.index %w[prometheus_alert_id payload_key], name: "index_prometheus_alert_event_scoped_payload_key", unique: true, using: :btree
    end

    create_table_if_not_exists "prometheus_alerts" do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.float "threshold", null: false
      t.integer "operator", null: false
      t.integer "environment_id", null: false
      t.integer "project_id", null: false
      t.integer "prometheus_metric_id", null: false
      t.index ["environment_id"], name: "index_prometheus_alerts_on_environment_id", using: :btree
      t.index %w[project_id prometheus_metric_id environment_id], name: "index_prometheus_alerts_metric_environment", unique: true, using: :btree
      t.index ["prometheus_metric_id"], name: "index_prometheus_alerts_on_prometheus_metric_id", using: :btree
    end

    create_table_if_not_exists "protected_branch_unprotect_access_levels" do |t|
      t.integer "protected_branch_id", null: false
      t.integer "access_level", default: 40
      t.integer "user_id"
      t.integer "group_id"
      t.index ["group_id"], name: "index_protected_branch_unprotect_access_levels_on_group_id", using: :btree
      t.index ["protected_branch_id"], name: "index_protected_branch_unprotect_access", using: :btree
      t.index ["user_id"], name: "index_protected_branch_unprotect_access_levels_on_user_id", using: :btree
    end

    create_table_if_not_exists "protected_environment_deploy_access_levels" do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "access_level", default: 40
      t.integer "protected_environment_id", null: false
      t.integer "user_id"
      t.integer "group_id"
      t.index ["group_id"], name: "index_protected_environment_deploy_access_levels_on_group_id", using: :btree
      t.index ["protected_environment_id"], name: "index_protected_environment_deploy_access", using: :btree
      t.index ["user_id"], name: "index_protected_environment_deploy_access_levels_on_user_id", using: :btree
    end

    create_table_if_not_exists "protected_environments" do |t|
      t.integer "project_id", null: false
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.string "name", null: false
      t.index %w[project_id name], name: "index_protected_environments_on_project_id_and_name", unique: true, using: :btree
      t.index ["project_id"], name: "index_protected_environments_on_project_id", using: :btree
    end

    create_table_if_not_exists "push_rules" do |t|
      t.string "force_push_regex"
      t.string "delete_branch_regex"
      t.string "commit_message_regex"
      t.boolean "deny_delete_tag"
      t.integer "project_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.string "author_email_regex"
      t.boolean "member_check", default: false, null: false
      t.string "file_name_regex"
      t.boolean "is_sample", default: false
      t.integer "max_file_size", default: 0, null: false
      t.boolean "prevent_secrets", default: false, null: false
      t.string "branch_name_regex"
      t.boolean "reject_unsigned_commits"
      t.boolean "commit_committer_check"
      t.boolean "regexp_uses_re2", default: true
      t.string "commit_message_negative_regex"
      t.index ["is_sample"], name: "index_push_rules_on_is_sample", where: "is_sample", using: :btree
      t.index ["project_id"], name: "index_push_rules_on_project_id", using: :btree
    end

    create_table_if_not_exists "reviews", id: :bigserial do |t|
      t.integer "author_id"
      t.integer "merge_request_id", null: false
      t.integer "project_id", null: false
      t.datetime_with_timezone "created_at", null: false
      t.index ["author_id"], name: "index_reviews_on_author_id", using: :btree
      t.index ["merge_request_id"], name: "index_reviews_on_merge_request_id", using: :btree
      t.index ["project_id"], name: "index_reviews_on_project_id", using: :btree
    end

    create_table_if_not_exists "saml_providers" do |t|
      t.integer "group_id", null: false
      t.boolean "enabled", null: false
      t.string "certificate_fingerprint", null: false
      t.string "sso_url", null: false
      t.boolean "enforced_sso", default: false, null: false
      t.boolean "enforced_group_managed_accounts", default: false, null: false
      t.index ["group_id"], name: "index_saml_providers_on_group_id", using: :btree
    end

    create_table_if_not_exists "scim_oauth_access_tokens" do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "group_id", null: false
      t.string "token_encrypted", null: false
      t.index %w[group_id token_encrypted], name: "index_scim_oauth_access_tokens_on_group_id_and_token_encrypted", unique: true, using: :btree
    end

    create_table_if_not_exists "slack_integrations" do |t|
      t.integer "service_id", null: false
      t.string "team_id", null: false
      t.string "team_name", null: false
      t.string "alias", null: false
      t.string "user_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["service_id"], name: "index_slack_integrations_on_service_id", using: :btree
      t.index %w[team_id alias], name: "index_slack_integrations_on_team_id_and_alias", unique: true, using: :btree
    end

    create_table_if_not_exists "smartcard_identities", id: :bigserial do |t|
      t.integer "user_id", null: false
      t.string "subject", null: false
      t.string "issuer", null: false
      t.index %w[subject issuer], name: "index_smartcard_identities_on_subject_and_issuer", unique: true, using: :btree
      t.index ["user_id"], name: "index_smartcard_identities_on_user_id", using: :btree
    end

    create_table_if_not_exists "software_license_policies" do |t|
      t.integer "project_id", null: false
      t.integer "software_license_id", null: false
      t.integer "approval_status", default: 0, null: false
      t.index %w[project_id software_license_id], name: "index_software_license_policies_unique_per_project", unique: true, using: :btree
      t.index ["software_license_id"], name: "index_software_license_policies_on_software_license_id", using: :btree
    end

    create_table_if_not_exists "software_licenses" do |t|
      t.string "name", null: false
      t.index ["name"], name: "index_software_licenses_on_name", using: :btree
    end

    create_table_if_not_exists "users_ops_dashboard_projects", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "user_id", null: false
      t.integer "project_id", null: false
      t.index ["project_id"], name: "index_users_ops_dashboard_projects_on_project_id", using: :btree
      t.index %w[user_id project_id], name: "index_users_ops_dashboard_projects_on_user_id_and_project_id", unique: true, using: :btree
    end

    create_table_if_not_exists "vulnerability_feedback" do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "feedback_type", limit: 2, null: false
      t.integer "category", limit: 2, null: false
      t.integer "project_id", null: false
      t.integer "author_id", null: false
      t.integer "pipeline_id"
      t.integer "issue_id"
      t.string "project_fingerprint", limit: 40, null: false
      t.integer "merge_request_id"
      t.index ["author_id"], name: "index_vulnerability_feedback_on_author_id", using: :btree
      t.index ["issue_id"], name: "index_vulnerability_feedback_on_issue_id", using: :btree
      t.index ["merge_request_id"], name: "index_vulnerability_feedback_on_merge_request_id", using: :btree
      t.index ["pipeline_id"], name: "index_vulnerability_feedback_on_pipeline_id", using: :btree
      t.index %w[project_id category feedback_type project_fingerprint], name: "vulnerability_feedback_unique_idx", unique: true, using: :btree
    end

    create_table_if_not_exists "vulnerability_identifiers", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "project_id", null: false
      t.binary "fingerprint", null: false
      t.string "external_type", null: false
      t.string "external_id", null: false
      t.string "name", null: false
      t.text "url"
      t.index %w[project_id fingerprint], name: "index_vulnerability_identifiers_on_project_id_and_fingerprint", unique: true, using: :btree
    end

    create_table_if_not_exists "vulnerability_occurrence_identifiers", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.bigint "occurrence_id", null: false
      t.bigint "identifier_id", null: false
      t.index ["identifier_id"], name: "index_vulnerability_occurrence_identifiers_on_identifier_id", using: :btree
      t.index %w[occurrence_id identifier_id], name: "index_vulnerability_occurrence_identifiers_on_unique_keys", unique: true, using: :btree
    end

    create_table_if_not_exists "vulnerability_occurrence_pipelines", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.bigint "occurrence_id", null: false
      t.integer "pipeline_id", null: false
      t.index %w[occurrence_id pipeline_id], name: "vulnerability_occurrence_pipelines_on_unique_keys", unique: true, using: :btree
      t.index ["pipeline_id"], name: "index_vulnerability_occurrence_pipelines_on_pipeline_id", using: :btree
    end

    create_table_if_not_exists "vulnerability_occurrences", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "severity", limit: 2, null: false
      t.integer "confidence", limit: 2, null: false
      t.integer "report_type", limit: 2, null: false
      t.integer "project_id", null: false
      t.bigint "scanner_id", null: false
      t.bigint "primary_identifier_id", null: false
      t.binary "project_fingerprint", null: false
      t.binary "location_fingerprint", null: false
      t.string "uuid", limit: 36, null: false
      t.string "name", null: false
      t.string "metadata_version", null: false
      t.text "raw_metadata", null: false
      t.index ["primary_identifier_id"], name: "index_vulnerability_occurrences_on_primary_identifier_id", using: :btree
      t.index %w[project_id primary_identifier_id location_fingerprint scanner_id], name: "index_vulnerability_occurrences_on_unique_keys", unique: true, using: :btree
      t.index ["scanner_id"], name: "index_vulnerability_occurrences_on_scanner_id", using: :btree
      t.index ["uuid"], name: "index_vulnerability_occurrences_on_uuid", unique: true, using: :btree
    end

    create_table_if_not_exists "vulnerability_scanners", id: :bigserial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.integer "project_id", null: false
      t.string "external_id", null: false
      t.string "name", null: false
      t.index %w[project_id external_id], name: "index_vulnerability_scanners_on_project_id_and_external_id", unique: true, using: :btree
    end

    create_table_if_not_exists "dependency_proxy_blobs", id: :serial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.text "file", null: false
      t.string "file_name", null: false
      t.integer "file_store"
      t.integer "group_id", null: false
      t.bigint "size"
      t.datetime_with_timezone "updated_at", null: false
      t.index %w[group_id file_name], name: "index_dependency_proxy_blobs_on_group_id_and_file_name", using: :btree
    end

    create_table_if_not_exists "dependency_proxy_group_settings", id: :serial do |t|
      t.datetime_with_timezone "created_at", null: false
      t.boolean "enabled", default: false, null: false
      t.integer "group_id", null: false
      t.datetime_with_timezone "updated_at", null: false
      t.index ["group_id"], name: "index_dependency_proxy_group_settings_on_group_id", using: :btree
    end
  end

  def remove_tables
    drop_table_if_exists "approval_merge_request_rule_sources"
    drop_table_if_exists "approval_merge_request_rules"
    drop_table_if_exists "approval_merge_request_rules_approved_approvers"
    drop_table_if_exists "approval_merge_request_rules_groups"
    drop_table_if_exists "approval_merge_request_rules_users"
    drop_table_if_exists "approval_project_rules"
    drop_table_if_exists "approval_project_rules_groups"
    drop_table_if_exists "approval_project_rules_users"
    drop_table_if_exists "approvals"
    drop_table_if_exists "approver_groups"
    drop_table_if_exists "approvers"
    drop_table_if_exists "board_assignees"
    drop_table_if_exists "board_labels"
    drop_table_if_exists "ci_sources_pipelines"
    drop_table_if_exists "design_management_designs_versions"
    drop_table_if_exists "design_management_versions"
    drop_table_if_exists "design_management_designs"
    drop_table_if_exists "draft_notes"
    drop_table_if_exists "elasticsearch_indexed_namespaces"
    drop_table_if_exists "elasticsearch_indexed_projects"
    drop_table_if_exists "epic_issues"
    drop_table_if_exists "epic_metrics"
    drop_table_if_exists "epics"
    drop_table_if_exists "geo_cache_invalidation_events"
    drop_table_if_exists "geo_event_log"
    drop_table_if_exists "geo_hashed_storage_attachments_events"
    drop_table_if_exists "geo_hashed_storage_migrated_events"
    drop_table_if_exists "geo_job_artifact_deleted_events"
    drop_table_if_exists "geo_lfs_object_deleted_events"
    drop_table_if_exists "geo_node_namespace_links"
    drop_table_if_exists "geo_node_statuses"
    drop_table_if_exists "geo_nodes"
    drop_table_if_exists "geo_repositories_changed_events"
    drop_table_if_exists "geo_repository_created_events"
    drop_table_if_exists "geo_repository_deleted_events"
    drop_table_if_exists "geo_repository_renamed_events"
    drop_table_if_exists "geo_repository_updated_events"
    drop_table_if_exists "geo_reset_checksum_events"
    drop_table_if_exists "geo_upload_deleted_events"
    drop_table_if_exists "gitlab_subscriptions"
    drop_table_if_exists "historical_data"
    drop_table_if_exists "index_statuses"
    drop_table_if_exists "insights"
    drop_table_if_exists "issue_links"
    drop_table_if_exists "jira_connect_subscriptions"
    drop_table_if_exists "jira_connect_installations"
    drop_table_if_exists "ldap_group_links"
    drop_table_if_exists "licenses"
    drop_table_if_exists "namespace_statistics"
    drop_table_if_exists "operations_feature_flag_scopes"
    drop_table_if_exists "operations_feature_flags"
    drop_table_if_exists "operations_feature_flags_clients"
    drop_table_if_exists "packages_maven_metadata"
    drop_table_if_exists "packages_package_files"
    drop_table_if_exists "packages_packages"
    drop_table_if_exists "path_locks"
    drop_table_if_exists "plans"
    drop_table_if_exists "project_alerting_settings"
    drop_table_if_exists "project_feature_usages"
    drop_table_if_exists "project_incident_management_settings"
    drop_table_if_exists "project_repository_states"
    drop_table_if_exists "project_tracing_settings"
    drop_table_if_exists "prometheus_alert_events"
    drop_table_if_exists "prometheus_alerts"
    drop_table_if_exists "protected_branch_unprotect_access_levels"
    drop_table_if_exists "protected_environment_deploy_access_levels"
    drop_table_if_exists "protected_environments"
    drop_table_if_exists "push_rules"
    drop_table_if_exists "reviews"
    drop_table_if_exists "saml_providers"
    drop_table_if_exists "scim_oauth_access_tokens"
    drop_table_if_exists "slack_integrations"
    drop_table_if_exists "smartcard_identities"
    drop_table_if_exists "software_license_policies"
    drop_table_if_exists "software_licenses"
    drop_table_if_exists "users_ops_dashboard_projects"
    drop_table_if_exists "vulnerability_feedback"
    drop_table_if_exists "vulnerability_identifiers"
    drop_table_if_exists "vulnerability_occurrence_identifiers"
    drop_table_if_exists "vulnerability_occurrence_pipelines"
    drop_table_if_exists "vulnerability_occurrences"
    drop_table_if_exists "vulnerability_scanners"
    drop_table_if_exists "dependency_proxy_blobs"
    drop_table_if_exists "dependency_proxy_group_settings"
  end

  def add_missing_foreign_keys
    add_concurrent_foreign_key("application_settings", "namespaces", column: "custom_project_templates_group_id", name: "fk_rails_b53e481273", on_delete: :nullify)
    add_concurrent_foreign_key("application_settings", "projects", column: "file_template_project_id", name: "fk_ec757bd087", on_delete: :nullify)
    add_concurrent_foreign_key("approval_merge_request_rule_sources", "approval_merge_request_rules", column: "approval_merge_request_rule_id", name: "fk_rails_e605a04f76", on_delete: :cascade)
    add_concurrent_foreign_key("approval_merge_request_rule_sources", "approval_project_rules", column: "approval_project_rule_id", name: "fk_rails_64e8ed3c7e", on_delete: :cascade)
    add_concurrent_foreign_key("approval_merge_request_rules", "merge_requests", column: "merge_request_id", name: "fk_rails_004ce82224", on_delete: :cascade)
    add_concurrent_foreign_key("approval_merge_request_rules_approved_approvers", "approval_merge_request_rules", column: "approval_merge_request_rule_id", name: "fk_rails_6577725edb", on_delete: :cascade)
    add_concurrent_foreign_key("approval_merge_request_rules_approved_approvers", "users", column: "user_id", name: "fk_rails_8dc94cff4d", on_delete: :cascade)
    add_concurrent_foreign_key("approval_merge_request_rules_groups", "approval_merge_request_rules", column: "approval_merge_request_rule_id", name: "fk_rails_5b2ecf6139", on_delete: :cascade)
    add_concurrent_foreign_key("approval_merge_request_rules_groups", "namespaces", column: "group_id", name: "fk_rails_2020a7124a", on_delete: :cascade)
    add_concurrent_foreign_key("approval_merge_request_rules_users", "approval_merge_request_rules", column: "approval_merge_request_rule_id", name: "fk_rails_80e6801803", on_delete: :cascade)
    add_concurrent_foreign_key("approval_merge_request_rules_users", "users", column: "user_id", name: "fk_rails_bc8972fa55", on_delete: :cascade)
    add_concurrent_foreign_key("approval_project_rules", "projects", column: "project_id", name: "fk_rails_5fb4dd100b", on_delete: :cascade)
    add_concurrent_foreign_key("approval_project_rules_groups", "approval_project_rules", column: "approval_project_rule_id", name: "fk_rails_9071e863d1", on_delete: :cascade)
    add_concurrent_foreign_key("approval_project_rules_groups", "namespaces", column: "group_id", name: "fk_rails_396841e79e", on_delete: :cascade)
    add_concurrent_foreign_key("approval_project_rules_users", "approval_project_rules", column: "approval_project_rule_id", name: "fk_rails_b9e9394efb", on_delete: :cascade)
    add_concurrent_foreign_key("approval_project_rules_users", "users", column: "user_id", name: "fk_rails_f365da8250", on_delete: :cascade)
    add_concurrent_foreign_key("approvals", "merge_requests", column: "merge_request_id", name: "fk_310d714958", on_delete: :cascade)
    add_concurrent_foreign_key("approver_groups", "namespaces", column: "group_id", name: "fk_rails_1cdcbd7723", on_delete: :cascade)
    add_concurrent_foreign_key("board_assignees", "boards", column: "board_id", name: "fk_rails_3f6f926bd5", on_delete: :cascade)
    add_concurrent_foreign_key("board_assignees", "users", column: "assignee_id", name: "fk_rails_1c0ff59e82", on_delete: :cascade)
    add_concurrent_foreign_key("board_labels", "boards", column: "board_id", name: "fk_rails_9374a16edd", on_delete: :cascade)
    add_concurrent_foreign_key("board_labels", "labels", column: "label_id", name: "fk_rails_362b0600a3", on_delete: :cascade)
    add_concurrent_foreign_key("ci_sources_pipelines", "ci_builds", column: "source_job_id", name: "fk_be5624bf37", on_delete: :cascade)
    add_concurrent_foreign_key("ci_sources_pipelines", "ci_pipelines", column: "pipeline_id", name: "fk_e1bad85861", on_delete: :cascade)
    add_concurrent_foreign_key("ci_sources_pipelines", "ci_pipelines", column: "source_pipeline_id", name: "fk_d4e29af7d7", on_delete: :cascade)
    add_concurrent_foreign_key("ci_sources_pipelines", "projects", column: "source_project_id", name: "fk_acd9737679", on_delete: :cascade)
    add_concurrent_foreign_key("ci_sources_pipelines", "projects", column: "project_id", name: "fk_1e53c97c0a", on_delete: :cascade)
    add_concurrent_foreign_key("design_management_designs", "issues", column: "issue_id", name: "fk_rails_bfe283ec3c", on_delete: :cascade)
    add_concurrent_foreign_key("design_management_designs", "projects", column: "project_id", name: "fk_rails_4bb1073360", on_delete: :cascade)
    add_concurrent_foreign_key("design_management_designs_versions", "design_management_designs", column: "design_id", on_delete: :cascade)
    add_concurrent_foreign_key("design_management_designs_versions", "design_management_versions", column: "version_id", on_delete: :cascade)
    add_concurrent_foreign_key("draft_notes", "merge_requests", column: "merge_request_id", name: "fk_rails_e753681674", on_delete: :cascade)
    add_concurrent_foreign_key("draft_notes", "users", column: "author_id", name: "fk_rails_2a8dac9901", on_delete: :cascade)
    add_concurrent_foreign_key("elasticsearch_indexed_namespaces", "namespaces", column: "namespace_id", name: "fk_rails_bdcf044f37", on_delete: :cascade)
    add_concurrent_foreign_key("elasticsearch_indexed_projects", "projects", column: "project_id", name: "fk_rails_bd13bbdc3d", on_delete: :cascade)
    add_concurrent_foreign_key("epic_issues", "epics", column: "epic_id", name: "fk_rails_5d942936b4", on_delete: :cascade)
    add_concurrent_foreign_key("epic_issues", "issues", column: "issue_id", name: "fk_rails_4209981af6", on_delete: :cascade)
    add_concurrent_foreign_key("epic_metrics", "epics", column: "epic_id", name: "fk_rails_d071904753", on_delete: :cascade)
    add_concurrent_foreign_key("epics", "epics", column: "parent_id", name: "fk_25b99c1be3", on_delete: :cascade)
    add_concurrent_foreign_key("epics", "milestones", column: "milestone_id", name: "fk_rails_1bf671ebb7", on_delete: :nullify)
    add_concurrent_foreign_key("epics", "namespaces", column: "group_id", name: "fk_f081aa4489", on_delete: :cascade)
    add_concurrent_foreign_key("epics", "users", column: "assignee_id", name: "fk_dccd3f98fc", on_delete: :nullify)
    add_concurrent_foreign_key("epics", "users", column: "author_id", name: "fk_3654b61b03", on_delete: :cascade)
    add_concurrent_foreign_key("epics", "users", column: "closed_by_id", name: "fk_aa5798e761", on_delete: :nullify)
    add_concurrent_foreign_key("geo_event_log", "geo_cache_invalidation_events", column: "cache_invalidation_event_id", name: "fk_42c3b54bed", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_hashed_storage_migrated_events", column: "hashed_storage_migrated_event_id", name: "fk_27548c6db3", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_job_artifact_deleted_events", column: "job_artifact_deleted_event_id", name: "fk_176d3fbb5d", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_lfs_object_deleted_events", column: "lfs_object_deleted_event_id", name: "fk_d5af95fcd9", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_repositories_changed_events", column: "repositories_changed_event_id", name: "fk_4a99ebfd60", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_repository_created_events", column: "repository_created_event_id", name: "fk_9b9afb1916", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_repository_deleted_events", column: "repository_deleted_event_id", name: "fk_c4b1c1f66e", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_repository_renamed_events", column: "repository_renamed_event_id", name: "fk_86c84214ec", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_repository_updated_events", column: "repository_updated_event_id", name: "fk_78a6492f68", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_reset_checksum_events", column: "reset_checksum_event_id", name: "fk_cff7185ad2", on_delete: :cascade)
    add_concurrent_foreign_key("geo_event_log", "geo_upload_deleted_events", column: "upload_deleted_event_id", name: "fk_c1f241c70d", on_delete: :cascade)
    add_concurrent_foreign_key("geo_hashed_storage_attachments_events", "projects", column: "project_id", name: "fk_rails_d496b088e9", on_delete: :cascade)
    add_concurrent_foreign_key("geo_hashed_storage_migrated_events", "projects", column: "project_id", name: "fk_rails_687ed7d7c5", on_delete: :cascade)
    add_concurrent_foreign_key("geo_node_namespace_links", "geo_nodes", column: "geo_node_id", name: "fk_rails_546bf08d3e", on_delete: :cascade)
    add_concurrent_foreign_key("geo_node_namespace_links", "namespaces", column: "namespace_id", name: "fk_rails_41ff5fb854", on_delete: :cascade)
    add_concurrent_foreign_key("geo_node_statuses", "geo_nodes", column: "geo_node_id", name: "fk_rails_0ecc699c2a", on_delete: :cascade)
    add_concurrent_foreign_key("geo_repositories_changed_events", "geo_nodes", column: "geo_node_id", name: "fk_rails_75ec0fefcc", on_delete: :cascade)
    add_concurrent_foreign_key("geo_repository_created_events", "projects", column: "project_id", name: "fk_rails_1f49e46a61", on_delete: :cascade)
    add_concurrent_foreign_key("geo_repository_renamed_events", "projects", column: "project_id", name: "fk_rails_4e6524febb", on_delete: :cascade)
    add_concurrent_foreign_key("geo_repository_updated_events", "projects", column: "project_id", name: "fk_rails_2b70854c08", on_delete: :cascade)
    add_concurrent_foreign_key("geo_reset_checksum_events", "projects", column: "project_id", name: "fk_rails_910a06f12b", on_delete: :cascade)
    add_concurrent_foreign_key("gitlab_subscriptions", "namespaces", column: "namespace_id", name: "fk_e2595d00a1", on_delete: :cascade)
    add_concurrent_foreign_key("gitlab_subscriptions", "plans", column: "hosted_plan_id", name: "fk_bd0c4019c3", on_delete: :cascade)
    add_concurrent_foreign_key("identities", "saml_providers", column: "saml_provider_id", name: "fk_aade90f0fc", on_delete: :cascade)
    add_concurrent_foreign_key("index_statuses", "projects", column: "project_id", name: "fk_74b2492545", on_delete: :cascade)
    add_concurrent_foreign_key("insights", "namespaces", column: "namespace_id", name: "fk_rails_5c4391f60a", on_delete: nil)
    add_concurrent_foreign_key("insights", "projects", column: "project_id", name: "fk_rails_f36fda3932", on_delete: nil)
    add_concurrent_foreign_key("issue_links", "issues", column: "source_id", name: "fk_c900194ff2", on_delete: :cascade)
    add_concurrent_foreign_key("issue_links", "issues", column: "target_id", name: "fk_e71bb44f1f", on_delete: :cascade)
    add_concurrent_foreign_key("lists", "milestones", column: "milestone_id", name: "fk_rails_baed5f39b7", on_delete: :cascade)
    add_concurrent_foreign_key("lists", "users", column: "user_id", name: "fk_d6cf4279f7", on_delete: :cascade)
    add_concurrent_foreign_key("namespace_statistics", "namespaces", column: "namespace_id", name: "fk_rails_0062050394", on_delete: :cascade)
    add_concurrent_foreign_key("namespaces", "namespaces", column: "custom_project_templates_group_id", name: "fk_e7a0b20a6b", on_delete: :nullify)
    add_concurrent_foreign_key("namespaces", "plans", column: "plan_id", name: "fk_fdd12e5b80", on_delete: :nullify)
    add_concurrent_foreign_key("namespaces", "projects", column: "file_template_project_id", name: "fk_319256d87a", on_delete: :nullify)
    add_concurrent_foreign_key("notes", "reviews", column: "review_id", name: "fk_2e82291620", on_delete: :nullify)
    add_concurrent_foreign_key("operations_feature_flag_scopes", "operations_feature_flags", column: "feature_flag_id", name: "fk_rails_a50a04d0a4", on_delete: :cascade)
    add_concurrent_foreign_key("operations_feature_flags", "projects", column: "project_id", name: "fk_rails_648e241be7", on_delete: :cascade)
    add_concurrent_foreign_key("operations_feature_flags_clients", "projects", column: "project_id", name: "fk_rails_6650ed902c", on_delete: :cascade)
    add_concurrent_foreign_key("packages_maven_metadata", "packages_packages", column: "package_id", name: "fk_be88aed360", on_delete: :cascade)
    add_concurrent_foreign_key("packages_package_files", "packages_packages", column: "package_id", name: "fk_86f0f182f8", on_delete: :cascade)
    add_concurrent_foreign_key("packages_packages", "projects", column: "project_id", name: "fk_rails_e1ac527425", on_delete: :cascade)
    add_concurrent_foreign_key("path_locks", "projects", column: "project_id", name: "fk_5265c98f24", on_delete: :cascade)
    add_concurrent_foreign_key("path_locks", "users", column: "user_id", name: "fk_rails_762cdcf942", on_delete: nil)
    add_concurrent_foreign_key("project_alerting_settings", "projects", column: "project_id", name: "fk_rails_27a84b407d", on_delete: :cascade)
    add_concurrent_foreign_key("project_feature_usages", "projects", column: "project_id", name: "fk_rails_c22a50024b", on_delete: :cascade)
    add_concurrent_foreign_key("project_incident_management_settings", "projects", column: "project_id", name: "fk_rails_9c2ea1b7dd", on_delete: :cascade)
    add_concurrent_foreign_key("project_repository_states", "projects", column: "project_id", name: "fk_rails_0f2298ca8a", on_delete: :cascade)
    add_concurrent_foreign_key("project_tracing_settings", "projects", column: "project_id", name: "fk_rails_fe56f57fc6", on_delete: :cascade)
    add_concurrent_foreign_key("prometheus_alert_events", "projects", column: "project_id", name: "fk_rails_4675865839", on_delete: :cascade)
    add_concurrent_foreign_key("prometheus_alert_events", "prometheus_alerts", column: "prometheus_alert_id", name: "fk_rails_106f901176", on_delete: :cascade)
    add_concurrent_foreign_key("prometheus_alerts", "environments", column: "environment_id", name: "fk_rails_6d9b283465", on_delete: :cascade)
    add_concurrent_foreign_key("prometheus_alerts", "projects", column: "project_id", name: "fk_rails_f0e8db86aa", on_delete: :cascade)
    add_concurrent_foreign_key("prometheus_alerts", "prometheus_metrics", column: "prometheus_metric_id", name: "fk_rails_e6351447ec", on_delete: :cascade)
    add_concurrent_foreign_key("protected_branch_merge_access_levels", "namespaces", column: "group_id", name: "fk_98f3d044fe", on_delete: :cascade)
    add_concurrent_foreign_key("protected_branch_merge_access_levels", "users", column: "user_id", name: "fk_rails_5ffb4f3590", on_delete: nil)
    add_concurrent_foreign_key("protected_branch_push_access_levels", "namespaces", column: "group_id", name: "fk_7111b68cdb", on_delete: :cascade)
    add_concurrent_foreign_key("protected_branch_push_access_levels", "users", column: "user_id", name: "fk_rails_8dcb712d65", on_delete: nil)
    add_concurrent_foreign_key("protected_branch_unprotect_access_levels", "namespaces", column: "group_id", name: "fk_rails_5be1abfc25", on_delete: :cascade)
    add_concurrent_foreign_key("protected_branch_unprotect_access_levels", "protected_branches", column: "protected_branch_id", name: "fk_rails_e9eb8dc025", on_delete: :cascade)
    add_concurrent_foreign_key("protected_branch_unprotect_access_levels", "users", column: "user_id", name: "fk_rails_2d2aba21ef", on_delete: :cascade)
    add_concurrent_foreign_key("protected_environment_deploy_access_levels", "namespaces", column: "group_id", name: "fk_rails_45cc02a931", on_delete: :cascade)
    add_concurrent_foreign_key("protected_environment_deploy_access_levels", "protected_environments", column: "protected_environment_id", name: "fk_rails_898a13b650", on_delete: :cascade)
    add_concurrent_foreign_key("protected_environment_deploy_access_levels", "users", column: "user_id", name: "fk_rails_5b9f6970fe", on_delete: :cascade)
    add_concurrent_foreign_key("protected_environments", "projects", column: "project_id", name: "fk_rails_a354313d11", on_delete: :cascade)
    add_concurrent_foreign_key("push_rules", "projects", column: "project_id", name: "fk_83b29894de", on_delete: :cascade)
    add_concurrent_foreign_key("resource_label_events", "epics", column: "epic_id", name: "fk_rails_75efb0a653", on_delete: :cascade)
    add_concurrent_foreign_key("reviews", "merge_requests", column: "merge_request_id", name: "fk_rails_5ca11d8c31", on_delete: :cascade)
    add_concurrent_foreign_key("reviews", "projects", column: "project_id", name: "fk_rails_64798be025", on_delete: :cascade)
    add_concurrent_foreign_key("reviews", "users", column: "author_id", name: "fk_rails_29e6f859c4", on_delete: :nullify)
    add_concurrent_foreign_key("saml_providers", "namespaces", column: "group_id", name: "fk_rails_306d459be7", on_delete: :cascade)
    add_concurrent_foreign_key("scim_oauth_access_tokens", "namespaces", column: "group_id", name: "fk_rails_c84404fb6c", on_delete: :cascade)
    add_concurrent_foreign_key("slack_integrations", "services", column: "service_id", name: "fk_rails_73db19721a", on_delete: :cascade)
    add_concurrent_foreign_key("smartcard_identities", "users", column: "user_id", name: "fk_rails_4689f889a9", on_delete: :cascade)
    add_concurrent_foreign_key("software_license_policies", "projects", column: "project_id", name: "fk_rails_87b2247ce5", on_delete: :cascade)
    add_concurrent_foreign_key("software_license_policies", "software_licenses", column: "software_license_id", name: "fk_rails_7a7a2a92de", on_delete: :cascade)
    add_concurrent_foreign_key("users", "namespaces", column: "managing_group_id", name: "fk_a4b8fefe3e", on_delete: :nullify)
    add_concurrent_foreign_key("users_ops_dashboard_projects", "projects", column: "project_id", name: "fk_rails_9b4ebf005b", on_delete: :cascade)
    add_concurrent_foreign_key("users_ops_dashboard_projects", "users", column: "user_id", name: "fk_rails_220a0562db", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_feedback", "ci_pipelines", column: "pipeline_id", name: "fk_rails_20976e6fd9", on_delete: :nullify)
    add_concurrent_foreign_key("vulnerability_feedback", "issues", column: "issue_id", name: "fk_rails_8c77e5891a", on_delete: :nullify)
    add_concurrent_foreign_key("vulnerability_feedback", "merge_requests", column: "merge_request_id", name: "fk_563ff1912e", on_delete: :nullify)
    add_concurrent_foreign_key("vulnerability_feedback", "projects", column: "project_id", name: "fk_rails_debd54e456", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_feedback", "users", column: "author_id", name: "fk_rails_472f69b043", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_identifiers", "projects", column: "project_id", name: "fk_rails_a67a16c885", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_occurrence_identifiers", "vulnerability_identifiers", column: "identifier_id", name: "fk_rails_be2e49e1d0", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_occurrence_identifiers", "vulnerability_occurrences", column: "occurrence_id", name: "fk_rails_e4ef6d027c", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_occurrence_pipelines", "ci_pipelines", column: "pipeline_id", name: "fk_rails_6421e35d7d", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_occurrence_pipelines", "vulnerability_occurrences", column: "occurrence_id", name: "fk_rails_dc3ae04693", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_occurrences", "projects", column: "project_id", name: "fk_rails_90fed4faba", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_occurrences", "vulnerability_identifiers", column: "primary_identifier_id", name: "fk_rails_c8661a61eb", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_occurrences", "vulnerability_scanners", column: "scanner_id", name: "fk_rails_bf5b788ca7", on_delete: :cascade)
    add_concurrent_foreign_key("vulnerability_scanners", "projects", column: "project_id", name: "fk_rails_5c9d42a221", on_delete: :cascade)
    add_concurrent_foreign_key("dependency_proxy_blobs", "namespaces", column: "group_id", on_delete: :cascade)
    add_concurrent_foreign_key("dependency_proxy_group_settings", "namespaces", column: "group_id", on_delete: :cascade)
    add_concurrent_foreign_key("jira_connect_subscriptions", "jira_connect_installations", column: "jira_connect_installation_id", on_delete: :cascade)
    add_concurrent_foreign_key("jira_connect_subscriptions", "namespaces", column: "namespace_id", on_delete: :cascade)

    remove_foreign_key_without_error("protected_tag_create_access_levels", column: :group_id)
    add_concurrent_foreign_key("protected_tag_create_access_levels", "namespaces", column: :group_id, name: "fk_b4eb82fe3c", on_delete: :cascade)
  end

  def remove_foreign_keys
    remove_foreign_key_without_error("application_settings", column: "custom_project_templates_group_id")
    remove_foreign_key_without_error("application_settings", column: "file_template_project_id")
    remove_foreign_key_without_error("approval_merge_request_rule_sources", column: "approval_merge_request_rule_id")
    remove_foreign_key_without_error("approval_merge_request_rule_sources", column: "approval_project_rule_id")
    remove_foreign_key_without_error("approval_merge_request_rules", column: "merge_request_id")
    remove_foreign_key_without_error("approval_merge_request_rules_approved_approvers", column: "approval_merge_request_rule_id")
    remove_foreign_key_without_error("approval_merge_request_rules_approved_approvers", column: "user_id")
    remove_foreign_key_without_error("approval_merge_request_rules_groups", column: "approval_merge_request_rule_id")
    remove_foreign_key_without_error("approval_merge_request_rules_groups", column: "group_id")
    remove_foreign_key_without_error("approval_merge_request_rules_users", column: "approval_merge_request_rule_id")
    remove_foreign_key_without_error("approval_merge_request_rules_users", column: "user_id")
    remove_foreign_key_without_error("approval_project_rules", column: "project_id")
    remove_foreign_key_without_error("approval_project_rules_groups", column: "approval_project_rule_id")
    remove_foreign_key_without_error("approval_project_rules_groups", column: "group_id")
    remove_foreign_key_without_error("approval_project_rules_users", column: "approval_project_rule_id")
    remove_foreign_key_without_error("approval_project_rules_users", column: "user_id")
    remove_foreign_key_without_error("approvals", column: "merge_request_id")
    remove_foreign_key_without_error("approver_groups", column: "group_id")
    remove_foreign_key_without_error("board_assignees", column: "board_id")
    remove_foreign_key_without_error("board_assignees", column: "assignee_id")
    remove_foreign_key_without_error("board_labels", column: "board_id")
    remove_foreign_key_without_error("board_labels", column: "label_id")
    remove_foreign_key_without_error("ci_sources_pipelines", column: "source_job_id")
    remove_foreign_key_without_error("ci_sources_pipelines", column: "pipeline_id")
    remove_foreign_key_without_error("ci_sources_pipelines", column: "source_pipeline_id")
    remove_foreign_key_without_error("ci_sources_pipelines", column: "source_project_id")
    remove_foreign_key_without_error("ci_sources_pipelines", column: "project_id")
    remove_foreign_key_without_error("design_management_designs", column: "issue_id")
    remove_foreign_key_without_error("design_management_designs", column: "project_id")
    remove_foreign_key_without_error("design_management_versions", column: "design_management_design_id")
    remove_foreign_key_without_error("draft_notes", column: "merge_request_id")
    remove_foreign_key_without_error("draft_notes", column: "author_id")
    remove_foreign_key_without_error("elasticsearch_indexed_namespaces", column: "namespace_id")
    remove_foreign_key_without_error("elasticsearch_indexed_projects", column: "project_id")
    remove_foreign_key_without_error("epic_issues", column: "epic_id")
    remove_foreign_key_without_error("epic_issues", column: "issue_id")
    remove_foreign_key_without_error("epic_metrics", column: "epic_id")
    remove_foreign_key_without_error("epics", column: "parent_id")
    remove_foreign_key_without_error("epics", column: "milestone_id")
    remove_foreign_key_without_error("epics", column: "group_id")
    remove_foreign_key_without_error("epics", column: "assignee_id")
    remove_foreign_key_without_error("epics", column: "author_id")
    remove_foreign_key_without_error("epics", column: "closed_by_id")
    remove_foreign_key_without_error("geo_event_log", column: "cache_invalidation_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "hashed_storage_migrated_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "job_artifact_deleted_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "lfs_object_deleted_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "repositories_changed_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "repository_created_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "repository_deleted_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "repository_renamed_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "repository_updated_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "reset_checksum_event_id")
    remove_foreign_key_without_error("geo_event_log", column: "upload_deleted_event_id")
    remove_foreign_key_without_error("geo_hashed_storage_attachments_events", column: "project_id")
    remove_foreign_key_without_error("geo_hashed_storage_migrated_events", column: "project_id")
    remove_foreign_key_without_error("geo_node_namespace_links", column: "geo_node_id")
    remove_foreign_key_without_error("geo_node_namespace_links", column: "namespace_id")
    remove_foreign_key_without_error("geo_node_statuses", column: "geo_node_id")
    remove_foreign_key_without_error("geo_repositories_changed_events", column: "geo_node_id")
    remove_foreign_key_without_error("geo_repository_created_events", column: "project_id")
    remove_foreign_key_without_error("geo_repository_renamed_events", column: "project_id")
    remove_foreign_key_without_error("geo_repository_updated_events", column: "project_id")
    remove_foreign_key_without_error("geo_reset_checksum_events", column: "project_id")
    remove_foreign_key_without_error("gitlab_subscriptions", column: "namespace_id")
    remove_foreign_key_without_error("gitlab_subscriptions", column: "hosted_plan_id")
    remove_foreign_key_without_error("identities", column: "saml_provider_id")
    remove_foreign_key_without_error("index_statuses", column: "project_id")
    remove_foreign_key_without_error("insights", column: "namespace_id", on_delete: nil)
    remove_foreign_key_without_error("insights", column: "project_id", on_delete: nil)
    remove_foreign_key_without_error("issue_links", column: "source_id")
    remove_foreign_key_without_error("issue_links", column: "target_id")
    remove_foreign_key_without_error("lists", column: "milestone_id")
    remove_foreign_key_without_error("lists", column: "user_id")
    remove_foreign_key_without_error("namespace_statistics", column: "namespace_id")
    remove_foreign_key_without_error("namespaces", column: "custom_project_templates_group_id")
    remove_foreign_key_without_error("namespaces", column: "plan_id")
    remove_foreign_key_without_error("namespaces", column: "file_template_project_id")
    remove_foreign_key_without_error("notes", column: "review_id")
    remove_foreign_key_without_error("operations_feature_flag_scopes", column: "feature_flag_id")
    remove_foreign_key_without_error("operations_feature_flags", column: "project_id")
    remove_foreign_key_without_error("operations_feature_flags_clients", column: "project_id")
    remove_foreign_key_without_error("packages_maven_metadata", column: "package_id")
    remove_foreign_key_without_error("packages_package_files", column: "package_id")
    remove_foreign_key_without_error("packages_packages", column: "project_id")
    remove_foreign_key_without_error("path_locks", column: "project_id")
    remove_foreign_key_without_error("path_locks", column: "user_id", on_delete: nil)
    remove_foreign_key_without_error("project_alerting_settings", column: "project_id")
    remove_foreign_key_without_error("project_feature_usages", column: "project_id")
    remove_foreign_key_without_error("project_incident_management_settings", column: "project_id")
    remove_foreign_key_without_error("project_repository_states", column: "project_id")
    remove_foreign_key_without_error("project_tracing_settings", column: "project_id")
    remove_foreign_key_without_error("prometheus_alert_events", column: "project_id")
    remove_foreign_key_without_error("prometheus_alert_events", column: "prometheus_alert_id")
    remove_foreign_key_without_error("prometheus_alerts", column: "environment_id")
    remove_foreign_key_without_error("prometheus_alerts", column: "project_id")
    remove_foreign_key_without_error("prometheus_alerts", column: "prometheus_metric_id")
    remove_foreign_key_without_error("protected_branch_merge_access_levels", column: "group_id")
    remove_foreign_key_without_error("protected_branch_merge_access_levels", column: "user_id", on_delete: nil)
    remove_foreign_key_without_error("protected_branch_push_access_levels", column: "group_id")
    remove_foreign_key_without_error("protected_branch_push_access_levels", column: "user_id", on_delete: nil)
    remove_foreign_key_without_error("protected_branch_unprotect_access_levels", column: "group_id")
    remove_foreign_key_without_error("protected_branch_unprotect_access_levels", column: "protected_branch_id")
    remove_foreign_key_without_error("protected_branch_unprotect_access_levels", column: "user_id")
    remove_foreign_key_without_error("protected_environment_deploy_access_levels", column: "group_id")
    remove_foreign_key_without_error("protected_environment_deploy_access_levels", column: "protected_environment_id")
    remove_foreign_key_without_error("protected_environment_deploy_access_levels", column: "user_id")
    remove_foreign_key_without_error("protected_environments", column: "project_id")
    remove_foreign_key_without_error("push_rules", column: "project_id")
    remove_foreign_key_without_error("resource_label_events", column: "epic_id")
    remove_foreign_key_without_error("reviews", column: "merge_request_id")
    remove_foreign_key_without_error("reviews", column: "project_id")
    remove_foreign_key_without_error("reviews", column: "author_id")
    remove_foreign_key_without_error("saml_providers", column: "group_id")
    remove_foreign_key_without_error("scim_oauth_access_tokens", column: "group_id")
    remove_foreign_key_without_error("slack_integrations", column: "service_id")
    remove_foreign_key_without_error("smartcard_identities", column: "user_id")
    remove_foreign_key_without_error("software_license_policies", column: "project_id")
    remove_foreign_key_without_error("software_license_policies", column: "software_license_id")
    remove_foreign_key_without_error("users", column: "managing_group_id")
    remove_foreign_key_without_error("users_ops_dashboard_projects", column: "project_id")
    remove_foreign_key_without_error("users_ops_dashboard_projects", column: "user_id")
    remove_foreign_key_without_error("vulnerability_feedback", column: "pipeline_id")
    remove_foreign_key_without_error("vulnerability_feedback", column: "issue_id")
    remove_foreign_key_without_error("vulnerability_feedback", column: "merge_request_id")
    remove_foreign_key_without_error("vulnerability_feedback", column: "project_id")
    remove_foreign_key_without_error("vulnerability_feedback", column: "author_id")
    remove_foreign_key_without_error("vulnerability_identifiers", column: "project_id")
    remove_foreign_key_without_error("vulnerability_occurrence_identifiers", column: "identifier_id")
    remove_foreign_key_without_error("vulnerability_occurrence_identifiers", column: "occurrence_id")
    remove_foreign_key_without_error("vulnerability_occurrence_pipelines", column: "pipeline_id")
    remove_foreign_key_without_error("vulnerability_occurrence_pipelines", column: "occurrence_id")
    remove_foreign_key_without_error("vulnerability_occurrences", column: "project_id")
    remove_foreign_key_without_error("vulnerability_occurrences", column: "primary_identifier_id")
    remove_foreign_key_without_error("vulnerability_occurrences", column: "scanner_id")
    remove_foreign_key_without_error("vulnerability_scanners", column: "project_id")
    remove_foreign_key_without_error("dependency_proxy_blobs", column: "group_id")
    remove_foreign_key_without_error("dependency_proxy_group_settings", column: "group_id")
    remove_foreign_key_without_error("jira_connect_subscriptions", "jira_connect_installations", column: "jira_connect_installation_id")
    remove_foreign_key_without_error("jira_connect_subscriptions", "namespaces", column: "namespace_id")

    remove_foreign_key_without_error("protected_tag_create_access_levels", column: :group_id)
    add_concurrent_foreign_key("protected_tag_create_access_levels", "namespaces", column: :group_id, on_delete: nil)
  end
end
# rubocop: enable Metrics/AbcSize
# rubocop: enable Migration/Datetime
# rubocop: enable Migration/PreventStrings
# rubocop: enable Migration/AddLimitToTextColumns
