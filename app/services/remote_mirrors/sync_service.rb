# frozen_string_literal: true

module RemoteMirrors
  class SyncService < BaseService
    def execute(remote_mirror)
      return ServiceResponse.error(message: _('Access Denied')) unless allowed?
      return ServiceResponse.error(message: _('Mirror does not exist')) unless remote_mirror

      if remote_mirror.disabled?
        return ServiceResponse.error(
          message: _('Cannot proceed with the push mirroring. Please verify your mirror configuration.')
        )
      end

      remote_mirror.sync unless remote_mirror.update_in_progress?

      ServiceResponse.success
    end

    private

    def allowed?
      Ability.allowed?(current_user, :admin_remote_mirror, project)
    end
  end
end
