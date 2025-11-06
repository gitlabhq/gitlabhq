# frozen_string_literal: true

module MergeRequests
  class AfterCreateService < MergeRequests::BaseService
    include Gitlab::Utils::StrongMemoize

    def execute(merge_request)
      measure_duration(:ensure_merge_request_diff) do
        merge_request.ensure_merge_request_diff
      end

      measure_duration(:prepare_for_mergeability) do
        prepare_for_mergeability(merge_request)
      end

      measure_duration(:prepare_merge_request) do
        prepare_merge_request(merge_request)
      end

      measure_duration(:mark_merge_request_as_prepared) do
        mark_merge_request_as_prepared(merge_request)
      end

      logger.info(**log_payload(merge_request, 'Executing hooks'))
      measure_duration(:execute_hooks) do
        execute_hooks(merge_request)
      end
      logger.info(**log_payload(merge_request, 'Executed hooks'))

      return unless log_after_create_duration_enabled?

      log_hash_metadata_on_done(duration_statistics)
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

    def measure_duration(operation_name)
      return yield unless log_after_create_duration_enabled?

      start_time = current_monotonic_time
      result = yield
      duration = (current_monotonic_time - start_time).round(Gitlab::InstrumentationHelper::DURATION_PRECISION)
      duration_statistics[:"#{operation_name}_duration_s"] = duration
      result
    end

    def duration_statistics
      @duration_statistics ||= {}
    end

    def log_after_create_duration_enabled?
      Feature.enabled?(:log_merge_request_after_create_duration, current_user)
    end
    strong_memoize_attr :log_after_create_duration_enabled?

    def log_hash_metadata_on_done(hash)
      total_duration = hash.values.sum
      hash_with_total = hash.merge(after_create_service_total_duration_s: total_duration)

      Gitlab::AppJsonLogger.info(
        event: 'merge_requests_after_create_service',
        **hash_with_total
      )
    end

    def current_monotonic_time
      Gitlab::Metrics::System.monotonic_time
    end
  end
end

MergeRequests::AfterCreateService.prepend_mod_with('MergeRequests::AfterCreateService')
