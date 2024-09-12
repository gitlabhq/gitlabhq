# frozen_string_literal: true

module MergeRequests
  class AfterCreateService < MergeRequests::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(merge_request)
      merge_request.ensure_merge_request_diff

      prepare_for_mergeability(merge_request)
      prepare_merge_request(merge_request)

      mark_merge_request_as_prepared(merge_request)

      logger.info(**log_payload(merge_request, 'Executing hooks'))
      execute_hooks(merge_request)
      logger.info(**log_payload(merge_request, 'Executed hooks'))
    end

    private

    def prepare_for_mergeability(merge_request)
      logger.info(**log_payload(merge_request, 'Creating pipeline'))
      create_pipeline_for(merge_request, current_user)
      logger.info(**log_payload(merge_request, 'Pipeline created'))
      merge_request.update_head_pipeline
      check_mergeability(merge_request)
    end

    def prepare_merge_request(merge_request)
      event_service.open_mr(merge_request, current_user)

      merge_request_activity_counter.track_create_mr_action(user: current_user, merge_request: merge_request)
      merge_request_activity_counter.track_mr_including_ci_config(user: current_user, merge_request: merge_request)

      notification_service.new_merge_request(merge_request, current_user)

      merge_request.diffs(include_stats: false).write_cache
      merge_request.create_cross_references!(current_user)

      todo_service.new_merge_request(merge_request, current_user)
      merge_request.cache_merge_request_closes_issues!(current_user)

      Gitlab::InternalEvents.track_event(
        'create_merge_request',
        user: current_user,
        project: merge_request.target_project
      )
      link_lfs_objects(merge_request)
    end

    def link_lfs_objects(merge_request)
      LinkLfsObjectsService.new(project: merge_request.target_project).execute(merge_request)
    end

    def check_mergeability(merge_request)
      return unless merge_request.preparing?

      # Need to set to unchecked to be able to check for mergeability or else
      # it'll be a no-op.
      merge_request.mark_as_unchecked
      merge_request.check_mergeability(async: true)
    end

    def mark_merge_request_as_prepared(merge_request)
      merge_request.update!(prepared_at: Time.current)
    end

    def logger
      @logger ||= Gitlab::AppLogger
    end

    def log_payload(merge_request, message)
      Gitlab::ApplicationContext.current.merge(
        merge_request_id: merge_request.id,
        message: message
      )
    end
  end
end

MergeRequests::AfterCreateService.prepend_mod_with('MergeRequests::AfterCreateService')
