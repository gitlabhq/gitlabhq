# frozen_string_literal: true

module Organizations
  class SoftDeleteService
    include BaseServiceUtility
    include ::Gitlab::Loggable

    def initialize(organization, current_user:)
      @organization = organization
      @current_user = current_user
    end

    def execute
      return error(_('Insufficient permissions'), reason: :access_denied) unless authorized?
      return error(_('Organization must be empty before it can be deleted')) unless organization.empty?
      return error(_('Organization has already been deleted')) if organization.soft_deleted?

      organization.soft_delete(transition_user: current_user)

      return error(organization.errors.full_messages.join(', ')) unless organization.soft_deleted?

      log_event

      ServiceResponse.success(payload: { organization: organization })
    end

    private

    attr_reader :organization, :current_user

    def authorized?
      Ability.allowed?(current_user, :delete_organization, organization)
    end

    def error(message, reason: nil)
      ServiceResponse.error(message: message, payload: { organization: nil }, reason: reason)
    end

    def log_event
      log_info(build_structured_payload(
        message: "Organization soft deleted",
        Labkit::Fields::GL_USER_ID => current_user.id,
        Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
        organization_path: organization.full_path
      ))
    end
  end
end

Organizations::SoftDeleteService.prepend_mod
