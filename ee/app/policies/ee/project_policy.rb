module EE
  module ProjectPolicy
    extend ActiveSupport::Concern

    prepended do
      with_scope :subject
      condition(:service_desk_enabled) { @subject.service_desk_enabled? }

      with_scope :subject
      condition(:related_issues_disabled) { !@subject.feature_available?(:related_issues) }

      with_scope :subject
      condition(:deploy_board_disabled) { !@subject.feature_available?(:deploy_board) }

      with_scope :global
      condition(:is_development) { Rails.env.development? }

      with_scope :global
      condition(:reject_unsigned_commits_disabled_globally) do
        !PushRule.global&.reject_unsigned_commits
      end

      with_scope :global
      condition(:commit_committer_check_disabled_globally) do
        !PushRule.global&.commit_committer_check
      end

      with_scope :global
      condition(:remote_mirror_available) do
        ::Gitlab::CurrentSettings.current_application_settings.remote_mirror_available
      end

      rule { admin }.enable :change_repository_storage

      rule { support_bot }.enable :guest_access
      rule { support_bot & ~service_desk_enabled }.policy do
        prevent :create_note
        prevent :read_project
      end

      rule { license_block }.policy do
        prevent :create_issue
        prevent :create_merge_request
        prevent :push_code
      end

      rule { related_issues_disabled }.policy do
        prevent :read_issue_link
        prevent :admin_issue_link
      end

      rule { can?(:read_issue) }.enable :read_issue_link

      rule { can?(:reporter_access) }.policy do
        enable :admin_board
        enable :read_deploy_board
        enable :admin_issue_link
        enable :admin_epic_issue
      end

      rule { can?(:developer_access) }.enable :admin_board

      rule { (remote_mirror_available & can?(:admin_project)) | admin }.enable :admin_remote_mirror

      rule { deploy_board_disabled & ~is_development }.prevent :read_deploy_board

      rule { can?(:master_access) }.policy do
        enable :push_code_to_protected_branches
        enable :admin_path_locks
        enable :update_approvers
      end

      rule { auditor }.policy do
        enable :public_user_access
        prevent :request_access

        enable :read_build
        enable :read_environment
        enable :read_deployment
        enable :read_pages
      end

      rule { auditor & ~guest }.policy do
        prevent :create_project
        prevent :create_issue
        prevent :create_note
        prevent :upload_file
      end

      rule { ~can?(:push_code) }.prevent :push_code_to_protected_branches

      rule { admin | (reject_unsigned_commits_disabled_globally & can?(:master_access)) }.enable :change_reject_unsigned_commits

      rule { admin | (commit_committer_check_disabled_globally & can?(:master_access)) }.enable :change_commit_committer_check
    end
  end
end
