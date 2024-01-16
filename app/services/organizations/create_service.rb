# frozen_string_literal: true

module Organizations
  class CreateService < ::Organizations::BaseService
    def execute
      return error_no_permissions unless current_user&.can?(:create_organization)

      organization = Organization.create(params)

      if organization.persisted?
        add_organization_owner(organization)

        ServiceResponse.success(payload: { organization: organization })
      else
        error_creating(organization)
      end
    end

    private

    def add_organization_owner(organization)
      organization.organization_users.create(user: current_user, access_level: :owner)
    end

    def error_no_permissions
      ServiceResponse.error(message: [_('You have insufficient permissions to create organizations')])
    end

    def error_creating(organization)
      message = organization.errors.full_messages || _('Failed to create organization')

      ServiceResponse.error(message: Array(message))
    end
  end
end
