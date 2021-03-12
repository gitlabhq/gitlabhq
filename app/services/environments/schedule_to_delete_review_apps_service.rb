# frozen_string_literal: true

module Environments
  class ScheduleToDeleteReviewAppsService < ::BaseService
    include ::Gitlab::ExclusiveLeaseHelpers

    EXCLUSIVE_LOCK_KEY_BASE = 'environments:delete_review_apps:lock'
    LOCK_TIMEOUT = 2.minutes

    def execute
      if validation_error = validate
        return validation_error
      end

      mark_deletable_environments
    end

    private

    def key
      "#{EXCLUSIVE_LOCK_KEY_BASE}:#{project.id}"
    end

    def dry_run?
      return true if params[:dry_run].nil?

      params[:dry_run]
    end

    def validate
      return if can?(current_user, :destroy_environment, project)

      Result.new(error_message: "You do not have permission to destroy environments in this project", status: :unauthorized)
    end

    def mark_deletable_environments
      in_lock(key, ttl: LOCK_TIMEOUT, retries: 1) do
        unsafe_mark_deletable_environments
      end

    rescue FailedToObtainLockError
      Result.new(error_message: "Another process is already processing a delete request. Please retry later.", status: :conflict)
    end

    def unsafe_mark_deletable_environments
      result = Result.new
      environments = project.environments
                            .not_scheduled_for_deletion
                            .stopped_review_apps(params[:before], params[:limit])

      # Check if the actor has write permission to a potentially-protected environment.
      deletable, failed = *environments.partition { |env| current_user.can?(:destroy_environment, env) }

      if deletable.any? && failed.empty?
        mark_for_deletion(deletable) unless dry_run?
        result.set_status(:ok)
        result.set_scheduled_entries(deletable)
      else
        result.set_status(
          :bad_request,
          error_message: "Failed to authorize deletions for some or all of the environments. Ask someone with more permissions to delete the environments."
        )

        result.set_unprocessable_entries(failed)
      end

      result
    end

    def mark_for_deletion(deletable_environments)
      Environment.for_id(deletable_environments).schedule_to_delete
    end

    class Result
      attr_accessor :scheduled_entries, :unprocessable_entries, :error_message, :status

      def initialize(scheduled_entries: [], unprocessable_entries: [], error_message: nil, status: nil)
        self.scheduled_entries = scheduled_entries
        self.unprocessable_entries = unprocessable_entries
        self.error_message = error_message
        self.status = status
      end

      def success?
        status == :ok
      end

      def set_status(status, error_message: nil)
        self.status = status
        self.error_message = error_message
      end

      def set_scheduled_entries(entries)
        self.scheduled_entries = entries
      end

      def set_unprocessable_entries(entries)
        self.unprocessable_entries = entries
      end
    end
  end
end
