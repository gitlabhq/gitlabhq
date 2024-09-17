# frozen_string_literal: true

module Search
  # Generates a list of all available setting sections of a group.
  # This list is used by the command palette's search functionality.
  class GroupSettings
    include Rails.application.routes.url_helpers

    attr_reader :group

    def initialize(group)
      @group = group
    end

    def all
      general_settings.concat(
        repository_settings,
        ci_cd_settings,
        packages_settings
      )
    end

    def general_settings
      [
        { text: _('Naming, description, visibility'), href: edit_group_path(group, anchor: 'js-general-settings') },
        { text: _('Permissions and group features'), href: edit_group_path(group, anchor: 'js-permissions-settings') },
        { text: _('Badges'), href: edit_group_path(group, anchor: 'js-badge-settings') },
        { text: _('Advanced'), href: edit_group_path(group, anchor: 'js-advanced-settings') }
      ]
    end

    def repository_settings
      [
        { text: _('Deploy tokens'), href: group_settings_repository_path(group, anchor: 'js-deploy-tokens') },
        { text: _('Default branch'), href: group_settings_repository_path(group, anchor: 'js-default-branch-name') }
      ]
    end

    def ci_cd_settings
      [
        { text: _('General pipelines'),
          href: group_settings_ci_cd_path(group, anchor: 'js-general-pipeline-settings') },
        { text: _('Variables'), href: group_settings_ci_cd_path(group, anchor: 'ci-variables') },
        { text: _('Runners'), href: group_settings_ci_cd_path(group, anchor: 'runners-settings') },
        { text: _('Auto DevOps'), href: group_settings_ci_cd_path(group, anchor: 'auto-devops-settings') }
      ]
    end

    def packages_settings
      [
        { text: _('Duplicate packages'),
          href: group_settings_packages_and_registries_path(group, anchor: 'packages-settings') },
        { text: _('Package forwarding'),
          href: group_settings_packages_and_registries_path(group, anchor: 'packages-forwarding-settings') },
        { text: _('Dependency Proxy'),
          href: group_settings_packages_and_registries_path(group, anchor: 'dependency-proxy-settings') }
      ]
    end
  end
end

Search::GroupSettings.prepend_mod
