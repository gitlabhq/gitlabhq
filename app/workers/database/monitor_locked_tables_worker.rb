# frozen_string_literal: true

module Database
  class MonitorLockedTablesWorker
    include ApplicationWorker
    include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

    sidekiq_options retry: false
    feature_category :cell
    data_consistency :sticky
    idempotent!

    version 1

    INITIAL_DATABASE_RESULT = {
      tables_need_lock: [],
      tables_need_lock_count: 0,
      tables_need_unlock: [],
      tables_need_unlock_count: 0
    }.freeze

    def perform
      return unless Gitlab::Database.database_mode == Gitlab::Database::MODE_MULTIPLE_DATABASES
      return if Feature.disabled?(:monitor_database_locked_tables, type: :ops)

      lock_writes_results = ::Gitlab::Database::TablesLocker.new(dry_run: true, include_partitions: false).lock_writes

      tables_lock_info_per_db = ::Gitlab::Database.database_base_models_with_gitlab_shared.keys.to_h do |db_name, _|
        [db_name, INITIAL_DATABASE_RESULT.deep_dup]
      end

      lock_writes_results.each do |result|
        handle_lock_writes_result(tables_lock_info_per_db, result)
      end

      tables_lock_info_per_db.each do |database_name, database_results|
        next if database_results[:tables_need_lock].empty?
        break if Feature.disabled?(:lock_tables_in_monitoring, type: :ops)

        LockTablesWorker.perform_async(database_name, database_results[:tables_need_lock])
      end

      log_extra_metadata_on_done(:results, tables_lock_info_per_db)
    end

    private

    def handle_lock_writes_result(results, result)
      case result[:action]
      when "needs_lock"
        results[result[:database]][:tables_need_lock] << result[:table]
        results[result[:database]][:tables_need_lock_count] += 1
      when "needs_unlock"
        results[result[:database]][:tables_need_unlock] << result[:table]
        results[result[:database]][:tables_need_unlock_count] += 1
      end
    end
  end
end
