# frozen_string_literal: true

module MergeRequests
  class CloseService < MergeRequests::BaseService
    include RemovesRefs

    def execute(merge_request, commit = nil, skip_reset: false)
      if Feature.enabled?(:destroy_fork_network_on_archive, project)
        unless params[:skip_authorization].present? || can?(current_user, :update_merge_request, merge_request)
          return merge_request
        end
      else
        return merge_request unless can?(current_user, :update_merge_request, merge_request)
      end

      use_primary(merge_request, skip_reset) do |merge_request|
        # If we close MergeRequest we want to ignore validation
        # so we can close broken one (Ex. fork project removed)
        merge_request.allow_broken = true

        if merge_request.close
          expire_unapproved_key(merge_request)
          create_event(merge_request)
          merge_request_activity_counter.track_close_mr_action(user: current_user)
          create_note(merge_request)
          notification_service.async.close_mr(merge_request, current_user)
          todo_service.close_merge_request(merge_request, current_user)
          execute_hooks(merge_request, 'close')
          invalidate_all_users_cache_count(merge_request)
          merge_request.invalidate_project_counter_caches
          cleanup_environments(merge_request)
          deactivate_pages_deployments(merge_request)
          abort_auto_merge(merge_request, 'merge request was closed')
          cleanup_refs(merge_request)
          trigger_merge_request_merge_status_updated(merge_request)
        end

        merge_request
      end
    end

    private

    def use_primary(merge_request, skip_reset)
      return yield(merge_request) if skip_reset

      ::Gitlab::Database::LoadBalancing::SessionMap.current(merge_request.load_balancer).use_primary do
        yield(merge_request.reset)
      end
    end

    def create_event(merge_request)
      # Making sure MergeRequest::Metrics updates are in sync with
      # Event creation.
      Event.transaction do
        close_event = event_service.close_mr(merge_request, current_user)
        merge_request_metrics_service(merge_request).close(close_event)
      end
    end

    def expire_unapproved_key(merge_request)
      nil
    end

    def trigger_merge_request_merge_status_updated(merge_request)
      GraphqlTriggers.merge_request_merge_status_updated(merge_request)
    end
  end
end

MergeRequests::CloseService.prepend_mod
