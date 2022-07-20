# frozen_string_literal: true

module WebHooks
  module WebHooksHelper
    EXPIRY_TTL = 1.hour

    def show_project_hook_failed_callout?(project:)
      return false unless current_user
      return false unless Feature.enabled?(:webhooks_failed_callout, project)
      return false unless Feature.enabled?(:web_hooks_disable_failed, project)
      return false unless Ability.allowed?(current_user, :read_web_hooks, project)

      # Assumes include of Users::CalloutsHelper
      return false if web_hook_disabled_dismissed?(project)

      any_project_hook_failed?(project) # Most expensive query last
    end

    private

    def any_project_hook_failed?(project)
      Rails.cache.fetch("any_web_hook_failed:#{project.id}", expires_in: EXPIRY_TTL) do
        ProjectHook.for_projects(project).disabled.exists?
      end
    end
  end
end
