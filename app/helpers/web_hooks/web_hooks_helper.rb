# frozen_string_literal: true

module WebHooks
  module WebHooksHelper
    def show_project_hook_failed_callout?(project:)
      return false if project_hook_page?

      show_hook_failed_callout?(project)
    end

    private

    def show_hook_failed_callout?(object)
      return false unless current_user

      return false unless can_access_web_hooks?(object)

      # Assumes include of Users::CalloutsHelper
      return false if web_hook_disabled_dismissed?(object)

      object.fetch_web_hook_failure
    end

    def project_hook_page?
      current_controller?('projects/hooks') || current_controller?('projects/hook_logs')
    end

    def can_access_web_hooks?(object)
      Ability.allowed?(current_user, :admin_web_hook, object)
    end
  end
end

WebHooks::WebHooksHelper.prepend_mod
