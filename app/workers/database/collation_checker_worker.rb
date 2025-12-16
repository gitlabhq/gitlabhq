# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- This is the best place for this module
  class CollationCheckerWorker
    include ApplicationWorker

    COLLATION_CHECK_CACHE_TTL = 1.week.to_i
    COLLATION_CHECK_CACHE_KEY = 'gitlab:database:collation_check:v1'

    feature_category :database
    sidekiq_options retry: false
    data_consistency :sticky
    deduplicate :until_executing
    idempotent!

    def perform
      result = Gitlab::Database::CollationChecker.run(database_name: 'main')

      result_with_metadata = {
        'metadata' => {
          'last_run_at' => Time.current.iso8601
        },
        'databases' => result
      }
      Rails.cache.write(COLLATION_CHECK_CACHE_KEY, result_with_metadata.to_json, expires_in: COLLATION_CHECK_CACHE_TTL)
    rescue StandardError => e
      Gitlab::AppLogger.error("CollationCheckerWorker failed: #{e.message}")
      raise
    end
  end
end
