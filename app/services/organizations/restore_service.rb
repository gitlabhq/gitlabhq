# frozen_string_literal: true

module Organizations
  class RestoreService
    include BaseServiceUtility
    include ::Gitlab::Loggable

    def initialize(organization, current_user:)
      @organization = organization
      @current_user = current_user
    end

    def execute
      return error(_('Insufficient permissions')) unless authorized?
      return error(_('Organization is not soft-deleted')) unless organization.soft_deleted?

      organization.restore(transition_user: current_user)

      return error(organization.errors.full_messages.to_sentence) unless organization.active?

      log_event

      ServiceResponse.success(payload: { organization: organization })
    end

    private

    attr_reader :organization, :current_user

    def authorized?
      Ability.allowed?(current_user, :restore_organization, organization)
    end

    def error(message)
      ServiceResponse.error(message: message, payload: { organization: nil })
    end

    def log_event
      log_info(build_structured_payload(
        message: "Organization restored",
        Labkit::Fields::GL_USER_ID => current_user.id,
        Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
        organization_path: organization.full_path
      ))
    end
  end
end

Organizations::RestoreService.prepend_mod
