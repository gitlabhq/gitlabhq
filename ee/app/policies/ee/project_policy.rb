module EE
  module ProjectPolicy
    extend ActiveSupport::Concern

    READONLY_FEATURES_WHEN_ARCHIVED = %i[
      board
      issue_link
      approvers
      vulnerability_feedback
      license_management
    ].freeze

    prepended do
      with_scope :subject
      condition(:service_desk_enabled) { @subject.service_desk_enabled? }

      with_scope :subject
      condition(:related_issues_disabled) { !@subject.feature_available?(:related_issues) }

      with_scope :subject
      condition(:repository_mirrors_enabled) { @subject.feature_available?(:repository_mirrors) }

      with_scope :subject
      condition(:deploy_board_disabled) { !@subject.feature_available?(:deploy_board) }

      with_scope :subject
      condition(:classification_label_authorized, score: 32) do
        EE::Gitlab::ExternalAuthorization.access_allowed?(
          @user,
          @subject.external_authorization_classification_label,
          @subject.full_path
        )
      end

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

      with_scope :subject
      condition(:pod_logs_enabled) do
        @subject.feature_available?(:pod_logs, @user)
      end

      with_scope :subject
      condition(:security_reports_feature_available) { @subject.security_reports_feature_available? }

      condition(:prometheus_alerts_enabled) do
        @subject.feature_available?(:prometheus_alerts, @user)
      end

      with_scope :subject
      condition(:license_management_enabled) do
        @subject.feature_available?(:license_management)
      end

      rule { admin }.enable :change_repository_storage

      rule { support_bot }.enable :guest_access
      rule { support_bot & ~service_desk_enabled }.policy do
        prevent :create_note
        prevent :read_project
      end

      rule { license_block }.policy do
        prevent :create_issue
        prevent :create_merge_request_in
        prevent :create_merge_request_from
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
        enable :read_packages
      end

      rule { can?(:developer_access) }.policy do
        enable :admin_board
        enable :admin_vulnerability_feedback
      end

      rule { can?(:developer_access) & security_reports_feature_available }.enable :read_project_security_dashboard

      rule { can?(:read_project) }.enable :read_vulnerability_feedback

      rule { license_management_enabled & can?(:read_project) }.enable :read_software_license_policy

      rule { repository_mirrors_enabled & ((mirror_available & can?(:admin_project)) | admin) }.enable :admin_mirror

      rule { deploy_board_disabled & ~is_development }.prevent :read_deploy_board

      rule { can?(:maintainer_access) }.policy do
        enable :push_code_to_protected_branches
        enable :admin_path_locks
        enable :update_approvers
      end

      rule { license_management_enabled & can?(:maintainer_access) }.enable :admin_software_license_policy

      rule { pod_logs_enabled & can?(:maintainer_access) }.enable :read_pod_logs
      rule { prometheus_alerts_enabled & can?(:maintainer_access) }.enable :read_prometheus_alerts

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

      rule { admin | (reject_unsigned_commits_disabled_globally & can?(:maintainer_access)) }.enable :change_reject_unsigned_commits

      rule { admin | (commit_committer_check_disabled_globally & can?(:maintainer_access)) }.enable :change_commit_committer_check

      rule { owner | reporter }.enable :build_read_project

      rule { ~can?(:read_cross_project) & ~classification_label_authorized }.policy do
        # Preventing access here still allows the projects to be listed. Listing
        # projects doesn't check the `:read_project` ability. But instead counts
        # on the `project_authorizations` table.
        #
        # All other actions should explicitly check read project, which would
        # trigger the `classification_label_authorized` condition.
        #
        # `:read_project_for_iids` is not prevented by this condition, as it is
        # used for cross-project reference checks.
        prevent :guest_access
        prevent :public_access
        prevent :public_user_access
        prevent :reporter_access
        prevent :developer_access
        prevent :maintainer_access
        prevent :owner_access
      end

      rule { archived }.policy do
        READONLY_FEATURES_WHEN_ARCHIVED.each do |feature|
          prevent(*::ProjectPolicy.create_update_admin_destroy(feature))
        end
      end
    end
  end
end
