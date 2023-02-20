# frozen_string_literal: true

module WebHooks
  module WebHooksHelper
    def show_project_hook_failed_callout?(project:)
      return false if project_hook_page?
      return false unless current_user
      return false unless Ability.allowed?(current_user, :read_web_hooks, project)

      # Assumes include of Users::CalloutsHelper
      return false if web_hook_disabled_dismissed?(project)

      project.fetch_web_hook_failure
    end

    private

    def project_hook_page?
      current_controller?('projects/hooks') || current_controller?('projects/hook_logs')
    end
  end
end
