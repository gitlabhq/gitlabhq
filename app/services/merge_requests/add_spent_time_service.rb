# frozen_string_literal: true

module MergeRequests
  class AddSpentTimeService < UpdateService
    def execute(merge_request)
      old_associations = { total_time_spent: merge_request.total_time_spent }

      merge_request.spend_time(params[:spend_time])

      merge_request_saved = merge_request.with_transaction_returning_status do
        merge_request.save
      end

      if merge_request_saved
        create_system_notes(merge_request)

        # track usage
        track_time_spend_edits(merge_request, old_associations[:total_time_spent])

        execute_hooks(merge_request, 'update', old_associations: old_associations)
      end

      merge_request
    end

    private

    def track_time_spend_edits(merge_request, old_total_time_spent)
      if old_total_time_spent != merge_request.total_time_spent
        merge_request_activity_counter.track_time_spent_changed_action(user: current_user)
      end
    end
  end
end
