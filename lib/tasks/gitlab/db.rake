namespace :gitlab do
  namespace :db do
    desc 'GitLab | Manually insert schema migration version'
    task :mark_migration_complete, [:version] => :environment do |_, args|
      unless args[:version]
        puts "Must specify a migration version as an argument".color(:red)
        exit 1
      end

      version = args[:version].to_i
      if version == 0
        puts "Version '#{args[:version]}' must be a non-zero integer".color(:red)
        exit 1
      end

      sql = "INSERT INTO schema_migrations (version) VALUES (#{version})"
      begin
        ActiveRecord::Base.connection.execute(sql)
        puts "Successfully marked '#{version}' as complete".color(:green)
      rescue ActiveRecord::RecordNotUnique
        puts "Migration version '#{version}' is already marked complete".color(:yellow)
      end
    end

    desc 'Drop all tables'
    task drop_tables: :environment do
      connection = ActiveRecord::Base.connection

      # If MySQL, turn off foreign key checks
      connection.execute('SET FOREIGN_KEY_CHECKS=0') if Gitlab::Database.mysql?

      tables = connection.tables
      tables.delete 'schema_migrations'
      # Truncate schema_migrations to ensure migrations re-run
      connection.execute('TRUNCATE schema_migrations')

      # Drop tables with cascade to avoid dependent table errors
      # PG: http://www.postgresql.org/docs/current/static/ddl-depend.html
      # MySQL: http://dev.mysql.com/doc/refman/5.7/en/drop-table.html
      # Add `IF EXISTS` because cascade could have already deleted a table.
      tables.each { |t| connection.execute("DROP TABLE IF EXISTS #{connection.quote_table_name(t)} CASCADE") }

      # If MySQL, re-enable foreign key checks
      connection.execute('SET FOREIGN_KEY_CHECKS=1') if Gitlab::Database.mysql?
    end

    desc 'Configures the database by running migrate, or by loading the schema and seeding if needed'
    task configure: :environment do
      if ActiveRecord::Base.connection.tables.any?
        Rake::Task['db:migrate'].invoke
      else
        Rake::Task['db:schema:load'].invoke
        Rake::Task['db:seed_fu'].invoke
      end
    end

    desc 'Checks if migrations require downtime or not'
    task :downtime_check, [:ref] => :environment do |_, args|
      abort 'You must specify a Git reference to compare with' unless args[:ref]

      require 'shellwords'

      ref = Shellwords.escape(args[:ref])

      migrations = `git diff #{ref}.. --diff-filter=A --name-only -- db/migrate`.lines
        .map { |file| Rails.root.join(file.strip).to_s }
        .select { |file| File.file?(file) }
        .select { |file| /\A[0-9]+.*\.rb\z/ =~ File.basename(file) }

      Gitlab::DowntimeCheck.new.check_and_print(migrations)
    end

    desc 'Output pseudonymity dump of selected table'
    task :pseudonymity_dump => :environment do

      # REMOVE PRODUCTION INFRA SCRIPT AS PART OF MR> 
      puts Pseudonymity::Table.table_to_csv("approvals",
        ["id","merge_request_id","user_id","created_at","updated_at"],
        ["id", "merge_request_id", "user_id"])
      puts Pseudonymity::Table.table_to_csv("approver_groups",
        ["id","target_type","group_id","created_at","updated_at"],
        ["id","group_id"])
      puts Pseudonymity::Table.table_to_csv("board_assignees",
        ["id","board_id","assignee_id"],
        ["id","board_id","assignee_id"])
      puts Pseudonymity::Table.table_to_csv("board_labels",
        ["id","board_id","label_id"],
        ["id","board_id","label_id"])
      puts Pseudonymity::Table.table_to_csv("boards",
        ["id","project_id","created_at","updated_at","milestone_id","group_id","weight"],
        ["id","project_id","milestone_id","group_id"])
      puts Pseudonymity::Table.table_to_csv("epic_issues",
        ["id","epic_id","issue_id","relative_position"],
        ["id","epic_id","issue_id"])
      puts Pseudonymity::Table.table_to_csv("epic_metrics",
        ["id","epic_id","created_at","updated_at"],
        ["id"])
      puts Pseudonymity::Table.table_to_csv("epics",
        ["id", "milestone_id", "group_id", "author_id", "assignee_id", "iid", "cached_markdown_version", "updated_by_id", "last_edited_by_id", "lock_version", "start_date", "end_date", "last_edited_at", "created_at", "updated_at", "title", "description"],
        ["id", "milestone_id", "group_id", "author_id", "assignee_id", "iid", "cached_markdown_version", "updated_by_id", "last_edited_by_id", "lock_version", "start_date", "end_date", "last_edited_at", "created_at", "updated_at"])
      puts Pseudonymity::Table.table_to_csv("issue_assignees",
        ["user_id","issue_id"],
        ["user_id","issue_id"])
      puts Pseudonymity::Table.table_to_csv("issue_links",
        ["id", "source_id", "target_id", "created_at", "updated_at"],
        ["id", "source_id", "target_id"])
      puts Pseudonymity::Table.table_to_csv("issue_metrics",
        ["id","issue_id","first_mentioned_in_commit_at","first_associated_with_milestone_at","first_added_to_board_at","created_at","updated_at"],
        ["id","issue_id"])
      puts Pseudonymity::Table.table_to_csv("issues",
        ["id","title","author_id","project_id","created_at","updated_at","description","milestone_id","state","updated_by_id","weight","due_date","moved_to_id","lock_version","time_estimate","last_edited_at","last_edited_by_id","discussion_locked","closed_at","closed_by_id"],
        ["id","title","author_id","project_id","description","milestone_id","state","updated_by_id","moved_to_id","discussion_locked","closed_at"])
      puts Pseudonymity::Table.table_to_csv("label_links",
        ["id","label_id","target_id","target_type","created_at","updated_at"],
        ["id","label_id","target_id"])
      puts Pseudonymity::Table.table_to_csv("label_priorities",
        ["id","project_id","label_id","priority","created_at","updated_at"],
        ["id","project_id","label_id"])
      puts Pseudonymity::Table.table_to_csv("labels",
        ["id","title","color","project_id","created_at","updated_at","template","type","group_id"],
        ["id","title","color","project_id","created_at","updated_at","template","type","group_id"])
      puts Pseudonymity::Table.table_to_csv("licenses",
        ["id","created_at","updated_at"],
        ["id"])
      puts Pseudonymity::Table.table_to_csv("licenses",
        ["id","created_at","updated_at"],
        ["id"])
      puts Pseudonymity::Table.table_to_csv("merge_request_diff_commits",
        ["authored_date","committed_date","merge_request_diff_id","relative_order","author_name","author_email","committer_name","committer_email"],
        ["merge_request_diff_id","author_name","author_email","committer_name","committer_email"])
      puts Pseudonymity::Table.table_to_csv("merge_request_diff_files",
        ["merge_request_diff_id","relative_order","new_file","renamed_file","deleted_file","too_large","a_mode","b_mode"],
        ["merge_request_diff_id"])
      puts Pseudonymity::Table.table_to_csv("merge_request_diffs",
        ["id","state","merge_request_id","created_at","updated_at","base_commit_sha","real_size","head_commit_sha","start_commit_sha","commits_count"],
        ["id","merge_request_id","base_commit_sha","head_commit_sha","start_commit_sha"])
      puts Pseudonymity::Table.table_to_csv("merge_request_metrics",
        ["id","merge_request_id","latest_build_started_at","latest_build_finished_at","first_deployed_to_production_at","merged_at","created_at","updated_at","pipeline_id","merged_by_id","latest_closed_by_id","latest_closed_at"],
        ["id","merge_request_id","pipeline_id","merged_by_id","latest_closed_by_id"])
      puts Pseudonymity::Table.table_to_csv("merge_requests",
        ["id","target_branch","source_branch","source_project_id","author_id","assignee_id","created_at","updated_at","milestone_id","state","merge_status","target_project_id","updated_by_id","merge_error","merge_params","merge_when_pipeline_succeeds","merge_user_id","approvals_before_merge","lock_version","time_estimate","squash","last_edited_at","last_edited_by_id","head_pipeline_id","discussion_locked","latest_merge_request_diff_id","allow_maintainer_to_push"],
        ["id","target_branch","source_branch","source_project_id","author_id","assignee_id","milestone_id","target_project_id","updated_by_id","merge_user_id","last_edited_by_id","head_pipeline_id","latest_merge_request_diff_id"])
      puts Pseudonymity::Table.table_to_csv("merge_requests_closing_issues",
        ["id","merge_request_id","issue_id","created_at","updated_at"],
        ["id","merge_request_id","issue_id"])
      puts Pseudonymity::Table.table_to_csv("milestones",
        ["id","project_id","due_date","created_at","updated_at","state","start_date","group_id"],
        ["id","project_id","group_id"])
      
      puts Pseudonymity::Table.table_to_csv("namespace_statistics",
        ["id","namespace_id" ,"shared_runners_seconds","shared_runners_seconds_last_reset"],
        ["id","namespace_id" ,"shared_runners_seconds","shared_runners_seconds_last_reset"])
      puts Pseudonymity::Table.table_to_csv("namespaces",
        ["id","name","path","owner_id","created_at","updated_at","type","description","avatar","membership_lock","share_with_group_lock","visibility_level","request_access_enabled","ldap_sync_status","ldap_sync_error","ldap_sync_last_update_at","ldap_sync_last_successful_update_at","ldap_sync_last_sync_at","description_html","lfs_enabled","parent_id","shared_runners_minutes_limit","repository_size_limit","require_two_factor_authentication","two_factor_grace_period","cached_markdown_version","plan_id","project_creation_level"],
        ["id","name","path","owner_id","created_at","updated_at","type","description","avatar","membership_lock","share_with_group_lock","visibility_level","request_access_enabled","ldap_sync_status","ldap_sync_error","ldap_sync_last_update_at","ldap_sync_last_successful_update_at","ldap_sync_last_sync_at","description_html","lfs_enabled","parent_id","shared_runners_minutes_limit","repository_size_limit","require_two_factor_authentication","two_factor_grace_period","cached_markdown_version","plan_id","project_creation_level"])
      puts Pseudonymity::Table.table_to_csv("notes",
        ["id","note","noteable_type","author_id","created_at","updated_at","project_id","attachment","line_code","commit_id","noteable_id","system","st_diff","updated_by_id","type","position","original_position","resolved_at","resolved_by_id","discussion_id","note_html","cached_markdown_version","change_position","resolved_by_push"],
        ["id","note","noteable_type","author_id","created_at","updated_at","project_id","attachment","line_code","commit_id","noteable_id","system","st_diff","updated_by_id","type","position","original_position","resolved_at","resolved_by_id","discussion_id","note_html","cached_markdown_version","change_position","resolved_by_push"])
      puts Pseudonymity::Table.table_to_csv("notification_settings",
        ["id","user_id","source_id","source_type","level","created_at","updated_at","new_note","new_issue","reopen_issue","close_issue","reassign_issue","new_merge_request","reopen_merge_request","close_merge_request","reassign_merge_request","merge_merge_request","failed_pipeline","success_pipeline","push_to_merge_request","issue_due"],
        ["id","user_id","source_id","source_type","level","created_at","updated_at","new_note","new_issue","reopen_issue","close_issue","reassign_issue","new_merge_request","reopen_merge_request","close_merge_request","reassign_merge_request","merge_merge_request","failed_pipeline","success_pipeline","push_to_merge_request","issue_due"])
      puts Pseudonymity::Table.table_to_csv("project_authorizations",
        ["user_id","project_id","access_level"],
        ["user_id","project_id","access_level"])
      puts Pseudonymity::Table.table_to_csv("project_auto_devops",
        ["id","project_id","created_at","updated_at","enabled","domain"],
        ["id","project_id","created_at","updated_at","enabled","domain"])
      puts Pseudonymity::Table.table_to_csv("project_ci_cd_settings",
        ["id","project_id","group_runners_enabled"],
        ["id","project_id","group_runners_enabled"])
      puts Pseudonymity::Table.table_to_csv("project_custom_attributes",
        ["id","created_at","updated_at","project_id","key","value"],
        ["id","created_at","updated_at","project_id","key","value"])
      puts Pseudonymity::Table.table_to_csv("project_deploy_tokens",
        ["id","project_id","deploy_token_id","created_at"],
        ["id","project_id","deploy_token_id","created_at"])
      puts Pseudonymity::Table.table_to_csv("project_features",
        ["id","project_id","merge_requests_access_level","issues_access_level","wiki_access_level","snippets_access_level","builds_access_level","created_at","updated_at","repository_access_level"],
        ["id","project_id","merge_requests_access_level","issues_access_level","wiki_access_level","snippets_access_level","builds_access_level","created_at","updated_at","repository_access_level"])
      puts Pseudonymity::Table.table_to_csv("project_group_links",
        ["id","project_id","group_id","created_at","updated_at","group_access","expires_at"],
        ["id","project_id","group_id","created_at","updated_at","group_access","expires_at"])
      puts Pseudonymity::Table.table_to_csv("project_import_data",
        ["id","project_id","data","encrypted_credentials","encrypted_credentials_iv","encrypted_credentials_salt"],
        ["id","project_id","data","encrypted_credentials","encrypted_credentials_iv","encrypted_credentials_salt"])
      puts Pseudonymity::Table.table_to_csv("project_mirror_data",
        ["id","project_id","retry_count","last_update_started_at","last_update_scheduled_at","next_execution_timestamp","created_at","updated_at"],
        ["id","project_id","retry_count","last_update_started_at","last_update_scheduled_at","next_execution_timestamp","created_at","updated_at"])
      puts Pseudonymity::Table.table_to_csv("project_repository_states",
        ["id","project_id","repository_verification_checksum","wiki_verification_checksum","last_repository_verification_failure","last_wiki_verification_failure"],
        ["id","project_id","repository_verification_checksum","wiki_verification_checksum","last_repository_verification_failure","last_wiki_verification_failure"])
      puts Pseudonymity::Table.table_to_csv("project_statistics",
        ["id","project_id","namespace_id","commit_count","storage_size","repository_size","lfs_objects_size","build_artifacts_size","shared_runners_seconds","shared_runners_seconds_last_reset"],
        ["id","project_id","namespace_id","commit_count","storage_size","repository_size","lfs_objects_size","build_artifacts_size","shared_runners_seconds","shared_runners_seconds_last_reset"])
      puts Pseudonymity::Table.table_to_csv("projects",
        ["id","name","path","description","created_at","updated_at","creator_id","namespace_id","last_activity_at","import_url","visibility_level","archived","avatar","import_status","merge_requests_template","star_count","merge_requests_rebase_enabled","import_type","import_source","approvals_before_merge","reset_approvals_on_push","merge_requests_ff_only_enabled","issues_template","mirror","mirror_last_update_at","mirror_last_successful_update_at","mirror_user_id","import_error","ci_id","shared_runners_enabled","runners_token","build_coverage_regex","build_allow_git_fetch","build_timeout","mirror_trigger_builds","pending_delete","public_builds","last_repository_check_failed","last_repository_check_at","container_registry_enabled","only_allow_merge_if_pipeline_succeeds","has_external_issue_tracker","repository_storage","repository_read_only","request_access_enabled","has_external_wiki","ci_config_path","lfs_enabled","description_html","only_allow_merge_if_all_discussions_are_resolved","repository_size_limit","printing_merge_request_link_enabled","auto_cancel_pending_pipelines","service_desk_enabled","import_jid","cached_markdown_version","delete_error","last_repository_updated_at","disable_overriding_approvers_per_merge_request","storage_version","resolve_outdated_diff_discussions","remote_mirror_available_overridden","only_mirror_protected_branches","pull_mirror_available_overridden","jobs_cache_index","mirror_overwrites_diverged_branches","external_authorization_classification_label","external_webhook_token","pages_https_only"],
        ["id","name","path","description","created_at","updated_at","creator_id","namespace_id","last_activity_at","import_url","visibility_level","archived","avatar","import_status","merge_requests_template","star_count","merge_requests_rebase_enabled","import_type","import_source","approvals_before_merge","reset_approvals_on_push","merge_requests_ff_only_enabled","issues_template","mirror","mirror_last_update_at","mirror_last_successful_update_at","mirror_user_id","import_error","ci_id","shared_runners_enabled","runners_token","build_coverage_regex","build_allow_git_fetch","build_timeout","mirror_trigger_builds","pending_delete","public_builds","last_repository_check_failed","last_repository_check_at","container_registry_enabled","only_allow_merge_if_pipeline_succeeds","has_external_issue_tracker","repository_storage","repository_read_only","request_access_enabled","has_external_wiki","ci_config_path","lfs_enabled","description_html","only_allow_merge_if_all_discussions_are_resolved","repository_size_limit","printing_merge_request_link_enabled","auto_cancel_pending_pipelines","service_desk_enabled","import_jid","cached_markdown_version","delete_error","last_repository_updated_at","disable_overriding_approvers_per_merge_request","storage_version","resolve_outdated_diff_discussions","remote_mirror_available_overridden","only_mirror_protected_branches","pull_mirror_available_overridden","jobs_cache_index","mirror_overwrites_diverged_branches","external_authorization_classification_label","external_webhook_token","pages_https_only"])
      puts Pseudonymity::Table.table_to_csv("subscriptions",
        ["id","user_id","subscribable_id","subscribable_type","subscribed","created_at","updated_at","project_id"],
        ["id","user_id","subscribable_id","subscribable_type","subscribed","created_at","updated_at","project_id"])
      puts Pseudonymity::Table.table_to_csv("users",
        ["id","email","encrypted_password","reset_password_token","reset_password_sent_at","remember_created_at","sign_in_count","current_sign_in_at","last_sign_in_at","current_sign_in_ip","last_sign_in_ip","created_at","updated_at","name","admin","projects_limit","skype","linkedin","twitter","bio","failed_attempts","locked_at","username","can_create_group","can_create_team","state","color_scheme_id","password_expires_at","created_by_id","last_credential_check_at","avatar","confirmation_token","confirmed_at","confirmation_sent_at","unconfirmed_email","hide_no_ssh_key","website_url","admin_email_unsubscribed_at","notification_email","hide_no_password","password_automatically_set","location","encrypted_otp_secret","encrypted_otp_secret_iv","encrypted_otp_secret_salt","otp_required_for_login","otp_backup_codes","public_email","dashboard","project_view","consumed_timestep","layout","hide_project_limit","note","unlock_token","otp_grace_period_started_at","external","incoming_email_token","organization","auditor","require_two_factor_authentication_from_group","two_factor_grace_period","ghost","last_activity_on","notified_of_own_activity","support_bot","preferred_language","rss_token","email_opted_in","email_opted_in_ip","email_opted_in_source_id","email_opted_in_at","theme_id"],
        ["id","email","encrypted_password","reset_password_token","reset_password_sent_at","remember_created_at","sign_in_count","current_sign_in_at","last_sign_in_at","current_sign_in_ip","last_sign_in_ip","created_at","updated_at","name","admin","projects_limit","skype","linkedin","twitter","bio","failed_attempts","locked_at","username","can_create_group","can_create_team","state","color_scheme_id","password_expires_at","created_by_id","last_credential_check_at","avatar","confirmation_token","confirmed_at","confirmation_sent_at","unconfirmed_email","hide_no_ssh_key","website_url","admin_email_unsubscribed_at","notification_email","hide_no_password","password_automatically_set","location","encrypted_otp_secret","encrypted_otp_secret_iv","encrypted_otp_secret_salt","otp_required_for_login","otp_backup_codes","public_email","dashboard","project_view","consumed_timestep","layout","hide_project_limit","note","unlock_token","otp_grace_period_started_at","external","incoming_email_token","organization","auditor","require_two_factor_authentication_from_group","two_factor_grace_period","ghost","last_activity_on","notified_of_own_activity","support_bot","preferred_language","rss_token","email_opted_in","email_opted_in_ip","email_opted_in_source_id","email_opted_in_at","theme_id"])
    end
  end
end
