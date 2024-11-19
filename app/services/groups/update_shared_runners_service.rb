# frozen_string_literal: true

module Groups
  class UpdateSharedRunnersService < Groups::BaseService
    def execute
      return error('Operation not allowed', 403) unless can?(current_user, :admin_runner, group)

      validate_params

      update_shared_runners
      update_pending_builds_async

      success

    rescue ActiveRecord::RecordInvalid, ArgumentError => error
      error(error.message)
    end

    private

    def validate_params
      unless Namespace::SHARED_RUNNERS_SETTINGS.include?(params[:shared_runners_setting])
        raise ArgumentError, "state must be one of: #{Namespace::SHARED_RUNNERS_SETTINGS.join(', ')}"
      end
    end

    def update_shared_runners
      case params[:shared_runners_setting]
      when Namespace::SR_DISABLED_AND_UNOVERRIDABLE
        set_shared_runners_enabled!(false)
      when Namespace::SR_DISABLED_AND_OVERRIDABLE
        disable_shared_runners_and_allow_override!
      when Namespace::SR_ENABLED
        set_shared_runners_enabled!(true)
      end
    end

    def update_pending_builds?
      group.previous_changes.include?('shared_runners_enabled')
    end

    def update_pending_builds_async
      return unless update_pending_builds?

      group.run_after_commit_or_now do |group|
        pending_builds_params = { 'instance_runners_enabled' => group.shared_runners_enabled }

        ::Ci::PendingBuilds::UpdateGroupWorker.perform_async(group.id, pending_builds_params)
      end
    end

    def set_shared_runners_enabled!(enabled)
      group.update!(
        shared_runners_enabled: enabled,
        allow_descendants_override_disabled_shared_runners: false)

      group_ids = group.descendants
      unless group_ids.empty?
        Group.by_id(group_ids).update_all(
          shared_runners_enabled: enabled,
          allow_descendants_override_disabled_shared_runners: false)
      end

      group.all_projects.update_all(shared_runners_enabled: enabled)
    end

    def disable_shared_runners_and_allow_override!
      # enabled -> disabled_and_overridable
      if group.shared_runners_enabled?
        group.update!(
          shared_runners_enabled: false,
          allow_descendants_override_disabled_shared_runners: true)

        group_ids = group.descendants
        Group.by_id(group_ids).update_all(shared_runners_enabled: false) unless group_ids.empty?

        group.all_projects.update_all(shared_runners_enabled: false)

      # disabled_and_unoverridable -> disabled_and_overridable
      else
        group.update!(allow_descendants_override_disabled_shared_runners: true)
      end
    end
  end
end
