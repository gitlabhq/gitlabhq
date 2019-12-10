# frozen_string_literal: true

module Environments
  class ResetAutoStopService < ::BaseService
    def execute(environment)
      return error(_('Failed to cancel auto stop because you do not have permission to update the environment.')) unless can_update_environment?(environment)
      return error(_('Failed to cancel auto stop because the environment is not set as auto stop.')) unless environment.auto_stop_at?

      if environment.reset_auto_stop
        success
      else
        error(_('Failed to cancel auto stop because failed to update the environment.'))
      end
    end

    private

    def can_update_environment?(environment)
      can?(current_user, :update_environment, environment)
    end
  end
end
