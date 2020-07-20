# frozen_string_literal: true

module Groups
  class UpdateSharedRunnersService < Groups::BaseService
    def execute
      return error('Operation not allowed', 403) unless can?(current_user, :admin_group, group)

      validate_params

      enable_or_disable_shared_runners!
      allow_or_disallow_descendants_override_disabled_shared_runners!

      success

    rescue Group::UpdateSharedRunnersError => error
      error(error.message)
    end

    private

    def validate_params
      if Gitlab::Utils.to_boolean(params[:shared_runners_enabled]) && !params[:allow_descendants_override_disabled_shared_runners].nil?
        raise Group::UpdateSharedRunnersError, 'Cannot set shared_runners_enabled to true and allow_descendants_override_disabled_shared_runners'
      end
    end

    def enable_or_disable_shared_runners!
      return if params[:shared_runners_enabled].nil?

      if Gitlab::Utils.to_boolean(params[:shared_runners_enabled])
        group.enable_shared_runners!
      else
        group.disable_shared_runners!
      end
    end

    def allow_or_disallow_descendants_override_disabled_shared_runners!
      return if params[:allow_descendants_override_disabled_shared_runners].nil?

      # Needs to reset group because if both params are present could result in error
      group.reset

      if Gitlab::Utils.to_boolean(params[:allow_descendants_override_disabled_shared_runners])
        group.allow_descendants_override_disabled_shared_runners!
      else
        group.disallow_descendants_override_disabled_shared_runners!
      end
    end
  end
end
