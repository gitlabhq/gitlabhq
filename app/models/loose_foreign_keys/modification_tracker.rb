# frozen_string_literal: true

module LooseForeignKeys
  class ModificationTracker
    MAX_DELETES = 100_000
    MAX_UPDATES = 50_000
    MAX_RUNTIME = 30.seconds # must be less than the scheduling frequency of the LooseForeignKeys::CleanupWorker cron worker

    delegate :monotonic_time, to: :'Gitlab::Metrics::System'

    def initialize
      @delete_count_by_table = Hash.new { |h, k| h[k] = 0 }
      @update_count_by_table = Hash.new { |h, k| h[k] = 0 }
      @start_time = monotonic_time
      @deletes_counter = Gitlab::Metrics.counter(
        :loose_foreign_key_deletions,
        'The number of loose foreign key deletions'
      )
      @updates_counter = Gitlab::Metrics.counter(
        :loose_foreign_key_updates,
        'The number of loose foreign key updates'
      )
    end

    def add_deletions(table, count)
      @delete_count_by_table[table] += count
      @deletes_counter.increment({ table: table }, count)
    end

    def add_updates(table, count)
      @update_count_by_table[table] += count
      @updates_counter.increment({ table: table }, count)
    end

    def over_limit?
      @delete_count_by_table.values.sum >= MAX_DELETES ||
        @update_count_by_table.values.sum >= MAX_UPDATES ||
        monotonic_time - @start_time >= MAX_RUNTIME
    end

    def stats
      {
        over_limit: over_limit?,
        delete_count_by_table: @delete_count_by_table,
        update_count_by_table: @update_count_by_table,
        delete_count: @delete_count_by_table.values.sum,
        update_count: @update_count_by_table.values.sum
      }
    end
  end
end
