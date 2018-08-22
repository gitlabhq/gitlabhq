module EE
  module ProjectsHelper
    extend ::Gitlab::Utils::Override

    override :sidebar_projects_paths
    def sidebar_projects_paths
      super + %w(projects/security/dashboard#show)
    end

    override :sidebar_settings_paths
    def sidebar_settings_paths
      super + %w(audit_events#index)
    end

    override :sidebar_repository_paths
    def sidebar_repository_paths
      super + %w(path_locks)
    end

    override :get_project_nav_tabs
    def get_project_nav_tabs(project, current_user)
      nav_tabs = super

      if ::Gitlab.config.packages.enabled && can?(current_user, :read_package, project)
        nav_tabs << :packages
      end

      nav_tabs
    end

    override :default_url_to_repo
    def default_url_to_repo(project = @project)
      case default_clone_protocol
      when 'krb5'
        project.kerberos_url_to_repo
      else
        super
      end
    end

    override :extra_default_clone_protocol
    def extra_default_clone_protocol
      if alternative_kerberos_url? && current_user
        "krb5"
      else
        super
      end
    end

    # Given the current GitLab configuration, check whether the GitLab URL for Kerberos is going to be different than the HTTP URL
    def alternative_kerberos_url?
      ::Gitlab.config.alternative_gitlab_kerberos_url?
    end

    def can_change_push_rule?(push_rule, rule)
      return true if push_rule.global?

      can?(current_user, :"change_#{rule}", @project)
    end

    def external_classification_label_help_message
      default_label = ::Gitlab::CurrentSettings.current_application_settings
                        .external_authorization_service_default_label

      s_(
        "ExternalAuthorizationService|When no classification label is set the "\
        "default label `%{default_label}` will be used."
      ) % { default_label: default_label }
    end

    def ci_cd_projects_available?
      ::License.feature_available?(:ci_cd_projects) && import_sources_enabled?
    end

    def size_limit_message(project)
      show_lfs = project.lfs_enabled? ? 'including files in LFS' : ''

      "The total size of this project's repository #{show_lfs} will be limited to this size. 0 for unlimited. Leave empty to inherit the group/global value."
    end

    def project_above_size_limit_message
      ::Gitlab::RepositorySizeError.new(@project).above_size_limit_message
    end

    def project_can_be_shared?
      !membership_locked? || @project.allowed_to_share_with_group?
    end

    def membership_locked?
      if @project.group && @project.group.membership_lock
        true
      else
        false
      end
    end

    def share_project_description
      share_with_group   = @project.allowed_to_share_with_group?
      share_with_members = !membership_locked?
      project_name       = content_tag(:strong, @project.name)
      member_message     = "You can add a new member to #{project_name}"

      description =
        if share_with_group && share_with_members
          "#{member_message} or share it with another group."
        elsif share_with_group
          "You can share #{project_name} with another group."
        elsif share_with_members
          "#{member_message}."
        end

      description.to_s.html_safe
    end

    def project_security_dashboard_config(project, pipeline)
      if pipeline.nil?
        {
          empty_state_illustration_path: image_path('illustrations/security-dashboard_empty.svg'),
          security_dashboard_help_path: help_page_path("user/project/security_dashboard"),
          has_pipeline_data: "false",
          can_create_feedback: "false",
          can_create_issue: "false"
        }
      else
        # Handle old job and artifact names for container scanning
        sast_container_head_path = if pipeline.expose_sast_container_data?
                                     sast_container_artifact_url(pipeline)
                                   elsif pipeline.expose_container_scanning_data?
                                     container_scanning_artifact_url(pipeline)
                                   else
                                     nil
                                   end

        {
          head_blob_path: project_blob_path(project, pipeline.sha),
          sast_head_path: pipeline.expose_sast_data? ? sast_artifact_url(pipeline) : nil,
          dependency_scanning_head_path: pipeline.expose_dependency_scanning_data? ? dependency_scanning_artifact_url(pipeline) : nil,
          dast_head_path: pipeline.expose_dast_data? ? dast_artifact_url(pipeline) : nil,
          sast_container_head_path: sast_container_head_path,
          vulnerability_feedback_path: project_vulnerability_feedback_index_path(project),
          pipeline_id: pipeline.id,
          vulnerability_feedback_help_path: help_page_path("user/project/merge_requests/index", anchor: "interacting-with-security-reports-ultimate"),
          sast_help_path: help_page_path('user/project/merge_requests/sast'),
          dependency_scanning_help_path: help_page_path('user/project/merge_requests/dependency_scanning'),
          dast_help_path: help_page_path('user/project/merge_requests/dast'),
          sast_container_help_path: help_page_path('user/project/merge_requests/sast_container'),
          user_path: user_url(pipeline.user),
          user_avatar_path: pipeline.user.avatar_url,
          user_name: pipeline.user.name,
          commit_id: pipeline.commit.short_id,
          commit_path: project_commit_url(project, pipeline.commit),
          ref_id: pipeline.ref,
          ref_path: project_commits_url(project, pipeline.ref),
          pipeline_path: pipeline_url(pipeline),
          pipeline_created: pipeline.created_at.to_s,
          has_pipeline_data: "true",
          can_create_feedback: can?(current_user, :admin_vulnerability_feedback, project).to_s,
          can_create_issue: can?(current_user, :create_issue, project).to_s
        }
      end
    end
  end
end
