# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- Database Framework
  class SchemaCheckerWorker
    include ApplicationWorker

    SCHEMA_CHECK_CACHE_TTL = 1.week.to_i
    SCHEMA_CHECK_CACHE_KEY = 'gitlab:database:schema_check:v1'

    feature_category :database
    sidekiq_options retry: false
    data_consistency :sticky
    deduplicate :until_executing
    idempotent!

    def perform
      result = Gitlab::Database::SchemaChecker.new(database_name: 'main').execute

      Rails.cache.write(SCHEMA_CHECK_CACHE_KEY, result.to_json, expires_in: SCHEMA_CHECK_CACHE_TTL)
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e)

      error_result = {
        error: true,
        message: e.message,
        metadata: {
          last_run_at: Time.current.iso8601
        }
      }
      Rails.cache.write(SCHEMA_CHECK_CACHE_KEY, error_result.to_json, expires_in: 1.hour)
    end
  end
end
