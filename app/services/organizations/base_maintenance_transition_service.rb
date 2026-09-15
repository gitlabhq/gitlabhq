# frozen_string_literal: true

module Organizations
  # Base class for the org_mover maintenance lifecycle transitions.
  #
  # Internal, JWT-gated services: authorization happens at the internal org_mover
  # API boundary (authenticate_by_gitlab_shell_token!), so they perform no
  # per-user ability check and take no current_user.
  #
  # Subclasses implement #execute. They share the response builders and logging
  # here, and run their guard + transition under `organization.with_lock` so the
  # check and the state change are atomic against concurrent transitions.
  class BaseMaintenanceTransitionService
    include BaseServiceUtility
    include ::Gitlab::Loggable

    def initialize(organization)
      @organization = organization
    end

    private

    attr_reader :organization

    def success
      ServiceResponse.success(payload: { organization: organization })
    end

    def error(message, reason: nil)
      ServiceResponse.error(message: message, reason: reason, payload: { organization: nil })
    end

    def transition_failed(fallback_message)
      error(organization.errors.full_messages.to_sentence.presence || fallback_message)
    end

    def log_event(message)
      log_info(build_structured_payload(
        message: message,
        Labkit::Fields::GL_ORGANIZATION_ID => organization.id
      ))
    end
  end
end
