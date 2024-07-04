# frozen_string_literal: true

module Search
  class Settings
    include Rails.application.routes.url_helpers

    def for_project(project)
      project_general_settings(project).concat(
        project_repository_settings(project),
        project_merge_request_settings(project),
        project_ci_cd_settings(project),
        project_monitor_settings(project)
      )
    end

    def project_general_settings(project)
      [
        { text: _("Naming, topics, avatar"), href: edit_project_path(project, anchor: 'js-general-settings') },
        { text: _("Visibility, project features, permissions"),
          href: edit_project_path(project, anchor: 'js-shared-permissions') },
        { text: _("Badges"), href: edit_project_path(project, anchor: 'js-badges-settings') },
        { text: _("Service Desk"), href: edit_project_path(project, anchor: 'js-service-desk') },
        { text: _("Advanced"), href: edit_project_path(project, anchor: 'js-project-advanced-settings') }
      ]
    end

    def project_repository_settings(project)
      [
        { text: _("Branch defaults"),
          href: project_settings_repository_path(project, anchor: 'branch-defaults-settings') },
        { text: _("Branch rules"), href: project_settings_repository_path(project, anchor: 'branch-rules') },
        { text: _("Mirroring repositories"),
          href: project_settings_repository_path(project, anchor: 'js-push-remote-settings') },
        { text: s_('DeployTokens|Deploy tokens'),
          href: project_settings_repository_path(project, anchor: 'js-deploy-tokens') },
        { text: _("Deploy keys"),
          href: project_settings_repository_path(project, anchor: 'js-deploy-keys-settings') },
        { text: _("Repository cleanup"), href: project_settings_repository_path(project, anchor: 'cleanup') }
      ]
    end

    def project_merge_request_settings(project)
      [
        { text: _("Merge requests"),
          href: project_settings_merge_requests_path(project, anchor: 'js-merge-request-settings') }
      ]
    end

    def project_ci_cd_settings(project)
      [
        { text: _("General pipelines"),
          href: project_settings_ci_cd_path(project, anchor: 'js-general-pipeline-settings') },
        { text: _("Auto DevOps"), href: project_settings_ci_cd_path(project, anchor: 'autodevops-settings') },
        { text: _("Runners"), href: project_settings_ci_cd_path(project, anchor: 'js-runners-settings') },
        { text: _("Artifacts"),     href: project_settings_ci_cd_path(project, anchor: 'js-artifacts-settings') },
        { text: _("Variables"),     href: project_settings_ci_cd_path(project, anchor: 'js-cicd-variables-settings') },
        { text: _("Pipeline trigger tokens"),
          href: project_settings_ci_cd_path(project, anchor: 'js-pipeline-triggers') },
        { text: _("Deploy freezes"),
          href: project_settings_ci_cd_path(project, anchor: 'js-deploy-freeze-settings') },
        { text: _("Job token permissions"), href: project_settings_ci_cd_path(project, anchor: 'js-token-access') },
        { text: _("Secure Files"),
          href: project_settings_ci_cd_path(project, anchor: 'js-secure-files') }
      ]
    end

    def project_monitor_settings(project)
      [
        { text: _("Error tracking"),
          href: project_settings_operations_path(project, anchor: 'js-error-tracking-settings') },
        { text: _("Alerts"),
          href: project_settings_operations_path(project, anchor: 'js-alert-management-settings') },
        { text: _("Incidents"),
          href: project_settings_operations_path(project, anchor: 'incident-management-settings') }
      ]
    end
  end
end

Search::Settings.prepend_mod
