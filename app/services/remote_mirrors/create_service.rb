# frozen_string_literal: true

module RemoteMirrors
  class CreateService < BaseService
    def execute
      return ServiceResponse.error(message: _('Access Denied')) unless allowed?

      remote_mirror = project.remote_mirrors.create(allowed_attributes)

      if remote_mirror.persisted?
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
