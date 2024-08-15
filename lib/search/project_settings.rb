# frozen_string_literal: true

module Search
  # Generates a list of all available setting sections of a project.
  # This list is used by the command palette's search functionality.
  class ProjectSettings
    include Rails.application.routes.url_helpers

    attr_reader :project

    def initialize(project)
      @project = project
    end

    def all
      general_settings.concat(
        repository_settings,
        merge_request_settings,
        ci_cd_settings,
        monitor_settings
      )
    end

    def general_settings
      [
        { text: _("Naming, description, topics"), href: edit_project_path(project, anchor: 'js-general-settings') },
        { text: _("Visibility, project features, permissions"),
          href: edit_project_path(project, anchor: 'js-shared-permissions') },
        { text: _("Badges"), href: edit_project_path(project, anchor: 'js-badges-settings') },
        { text: _("Service Desk"), href: edit_project_path(project, anchor: 'js-service-desk') },
        { text: _("Advanced"), href: edit_project_path(project, anchor: 'js-project-advanced-settings') }
      ]
    end

    def repository_settings
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

    def merge_request_settings
      [
        { text: _("Merge requests"),
          href: project_settings_merge_requests_path(project, anchor: 'js-merge-request-settings') }
      ]
    end

    def ci_cd_settings
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
        { text: _("Secure files"),
          href: project_settings_ci_cd_path(project, anchor: 'js-secure-files') }
      ]
    end

    def monitor_settings
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

Search::ProjectSettings.prepend_mod
