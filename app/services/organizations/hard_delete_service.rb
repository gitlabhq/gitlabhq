# frozen_string_literal: true

module Organizations
  class HardDeleteService
    include BaseServiceUtility
    include ::Gitlab::Loggable

    def initialize(organization, current_user:)
      @organization = organization
      @current_user = current_user
    end

    def async_execute
      return error(_('Insufficient permissions')) unless authorized?
      return error(_('Organization must be soft-deleted first')) unless organization.soft_deleted?

      mark_deletion_in_progress

      job_id = enqueue_hard_delete_worker
      return error(_('Failed to schedule organization deletion')) unless job_id

      log_scheduling(job_id)

      ServiceResponse.success(payload: { organization: organization })
    end

    def execute
      return error(_('Insufficient permissions')) unless authorized?

      unless organization.soft_deleted? || organization.deletion_in_progress?
        return error(_('Organization must be soft-deleted first'))
      end

      mark_deletion_in_progress

      organization_destroy

      ServiceResponse.success(payload: { organization: organization })
    end

    private

    attr_reader :organization, :current_user

    def mark_deletion_in_progress
      return if organization.deletion_in_progress?

      organization.hard_delete!(transition_user: current_user)
    end

    def organization_destroy
      organization_path = organization.full_path
      organization.destroy!

      log_event(organization_path)
    rescue StandardError => e
      abort_hard_deletion_safely
      log_failure('Organization hard deletion failed', e)
      raise
    end

    # Returns the Sidekiq job id, or nil if the enqueue failed. On failure the state
    # transition triggered by #async_execute is rolled back so the organization does
    # not get stuck in deletion_in_progress with no worker scheduled.
    def enqueue_hard_delete_worker
      Organizations::HardDeleteWorker.perform_async(organization.id, current_user.id)
    rescue StandardError => e
      abort_hard_deletion_safely
      log_failure('Organization hard deletion enqueue failed', e)
      nil
    end

    # Wraps the abort transition so a failure inside the rescue block cannot replace
    # the original error in flight.
    def abort_hard_deletion_safely
      return unless organization.deletion_in_progress?

      organization.abort_hard_deletion!(transition_user: current_user)
    rescue StandardError => rollback_error
      log_failure('Organization hard deletion rollback failed', rollback_error)
    end

    def authorized?
      Ability.allowed?(current_user, :delete_organization, organization)
    end

    def error(message)
      ServiceResponse.error(message: message, payload: { organization: nil })
    end

    def log_scheduling(job_id)
      log_info(log_payload('Organization hard deletion scheduled', job_id: job_id))
    end

    def log_event(organization_path)
      log_info(log_payload('Organization hard deleted', organization_path: organization_path))
    end

    def log_failure(message, error)
      log_error(log_payload(
        message,
        error_class: error.class.name,
        error_message: error.message
      ))
    end

    def log_payload(message, **extras)
      build_structured_payload(
        message: message,
        Labkit::Fields::GL_USER_ID => current_user.id,
        Labkit::Fields::GL_ORGANIZATION_ID => organization.id,
        organization_path: organization.full_path,
        **extras
      )
    end
  end
end

Organizations::HardDeleteService.prepend_mod
