# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- Existing module
module AutoMerge
  class MergeWhenChecksPassService < AutoMerge::BaseService
    extend Gitlab::Utils::Override

    override :execute
    def execute(merge_request)
      super do
        add_system_note(merge_request)
      end
    end

    override :process
    def process(merge_request)
      logger.info("Processing Automerge - MWCP")

      return if merge_request.has_ci_enabled? && !merge_request.diff_head_pipeline_success?

      logger.info("Pipeline Success - MWCP")

      return unless merge_request.mergeable?

      logger.info("Merge request mergeable - MWCP")

      merge_request.merge_async(merge_request.merge_user_id, merge_request.merge_params)
    end

    override :cancel
    def cancel(merge_request)
      super do
        SystemNoteService.cancel_auto_merge(merge_request, project, current_user)
      end
    end

    override :abort
    def abort(merge_request, reason)
      super do
        SystemNoteService.abort_auto_merge(merge_request, project, current_user, reason)
      end
    end

    # availability_details are responsible for validating whether the service is available_for a merge request and sets
    # an unavailable_reason if it is not
    override :availability_details
    def availability_details(merge_request)
      super do
        default_error = AutoMerge::AvailabilityCheck.error
        next default_error if merge_request.project.merge_trains_enabled?

        next default_error if merge_request.mergeable? && !merge_request.diff_head_pipeline_considered_in_progress? &&
          !merge_request.pipeline_creating?

        AutoMerge::AvailabilityCheck.success
      end
    end

    private

    def add_system_note(merge_request)
      return unless merge_request.saved_change_to_auto_merge_enabled?

      SystemNoteService.merge_when_checks_pass(
        merge_request,
        project,
        current_user,
        merge_request.merge_params.symbolize_keys[:sha]
      )
    end

    def notify(merge_request)
      return unless merge_request.saved_change_to_auto_merge_enabled?

      notification_service.async.merge_when_pipeline_succeeds(merge_request,
        current_user)
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts
