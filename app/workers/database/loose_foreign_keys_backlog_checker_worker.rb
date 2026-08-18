# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- Mirrors the sibling Database::*CheckerWorker classes
  # Measures the Loose Foreign Keys cleanup backlog and caches the result for the
  # /admin/database_diagnostics page.
  #
  # See Gitlab::Database::LooseForeignKeysBacklogChecker and
  # https://gitlab.com/gitlab-org/gitlab/-/issues/606252
  class LooseForeignKeysBacklogCheckerWorker
    include ApplicationWorker

    BACKLOG_CHECK_CACHE_TTL = 1.week.to_i
    BACKLOG_CHECK_CACHE_KEY = 'gitlab:database:loose_foreign_keys_backlog_check:v1'

    feature_category :database
    sidekiq_options retry: false
    data_consistency :sticky
    deduplicate :until_executing
    idempotent!

    def perform
      result = Gitlab::Database::LooseForeignKeysBacklogChecker.run

      result_with_metadata = {
        'metadata' => {
          'last_run_at' => Time.current.iso8601
        },
        'connections' => result
      }
      Rails.cache.write(BACKLOG_CHECK_CACHE_KEY, result_with_metadata.to_json, expires_in: BACKLOG_CHECK_CACHE_TTL)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)

      error_result = {
        'error' => true,
        'message' => e.message,
        'metadata' => {
          'last_run_at' => Time.current.iso8601
        }
      }
      Rails.cache.write(BACKLOG_CHECK_CACHE_KEY, error_result.to_json, expires_in: 1.hour)
    end
  end
end
