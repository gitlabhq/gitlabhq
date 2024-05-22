# frozen_string_literal: true

module RemoteMirrors # rubocop:disable Gitlab/BoundedContexts -- https://gitlab.com/gitlab-org/gitlab/-/issues/462816
  class UpdateService < BaseService
    def execute(remote_mirror)
      return ServiceResponse.error(message: _('Access Denied')) unless allowed?
      return ServiceResponse.error(message: _('Remote mirror is missing')) unless remote_mirror
      return ServiceResponse.error(message: _('Project mismatch')) unless remote_mirror.project == project

      if remote_mirror.update(allowed_attributes)
        ServiceResponse.success(payload: { remote_mirror: remote_mirror })
      else
        ServiceResponse.error(message: remote_mirror.errors)
      end
    end

    private

    def allowed_attributes
      RemoteMirrors::Attributes.new(params).allowed
    end

    def allowed?
      Ability.allowed?(current_user, :admin_remote_mirror, project)
    end
  end
end
