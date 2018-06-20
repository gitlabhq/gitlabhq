module EE
  module ProjectsHelper
    extend ::Gitlab::Utils::Override

    override :sidebar_settings_paths
    def sidebar_settings_paths
      super + %w(audit_events#index)
    end

    override :sidebar_repository_paths
    def sidebar_repository_paths
      super + %w(path_locks)
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
  end
end
