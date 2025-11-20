# frozen_string_literal: true

module MergeRequests
  class ReloadDiffsService
    include Gitlab::Utils::StrongMemoize

    def initialize(merge_request, current_user)
      @merge_request = merge_request
      @current_user = current_user
    end

    def execute(log_duration: false)
      @log_duration = log_duration

      old_diff_refs = measure_duration(:diff_refs) do
        merge_request.diff_refs
      end

      return if merge_request.reached_versions_limit?
      return if merge_request.reached_diff_commits_limit?

      new_diff = measure_duration(:create_merge_request_diff) do
        merge_request.create_merge_request_diff(preload_gitaly: true)
      end

      measure_duration(:clear_cache) do
        clear_cache(new_diff)
      end

      result = measure_duration(:update_diff_discussion_positions) do
        update_diff_discussion_positions(old_diff_refs)
      end

      log_duration_statistics if log_duration_enabled?

      result
    end

    private

    attr_reader :merge_request, :current_user

    def update_diff_discussion_positions(old_diff_refs)
      new_diff_refs = merge_request.diff_refs

      merge_request.update_diff_discussion_positions(
        old_diff_refs: old_diff_refs,
        new_diff_refs: new_diff_refs,
        current_user: current_user
      )
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def clear_cache(new_diff)
      # Remove cache for all diffs on this MR. Do not use the association on the
      # model, as that will interfere with other actions happening when
      # reloading the diff.
      MergeRequestDiff
        .where(merge_request: merge_request)
        .preload(merge_request: :target_project)
        .find_each do |merge_request_diff|
        next if merge_request_diff == new_diff

        cacheable_collection(merge_request_diff).clear_cache
      end
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def cacheable_collection(diff)
      # There are scenarios where we don't need to request Diff Stats.
      # Mainly when clearing / writing diff caches.
      diff.diffs(include_stats: false)
    end

    def measure_duration(operation_name)
      return yield unless log_duration_enabled?

      start_time = current_monotonic_time
      result = yield
      duration = (current_monotonic_time - start_time).round(Gitlab::InstrumentationHelper::DURATION_PRECISION)
      duration_statistics["#{operation_name}_duration_s"] = duration
      result
    end

    def duration_statistics
      @duration_statistics ||= {}
    end

    def log_duration_enabled?
      @log_duration && Feature.enabled?(:log_refresh_service_duration, current_user)
    end
    strong_memoize_attr :log_duration_enabled?

    def log_duration_statistics
      total_duration = duration_statistics.values.sum.round(Gitlab::InstrumentationHelper::DURATION_PRECISION)
      hash_with_total = duration_statistics.merge(
        'reload_diffs_service_total_duration_s' => total_duration
      )

      Gitlab::AppJsonLogger.info(
        'event' => 'merge_requests_reload_diffs_service',
        **hash_with_total
      )
    end

    def current_monotonic_time
      Gitlab::Metrics::System.monotonic_time
    end
  end
end
