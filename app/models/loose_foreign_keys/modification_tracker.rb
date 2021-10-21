# frozen_string_literal: true

module LooseForeignKeys
  class ModificationTracker
    MAX_DELETES = 100_000
    MAX_UPDATES = 50_000
    MAX_RUNTIME = 3.minutes

    delegate :monotonic_time, to: :'Gitlab::Metrics::System'

    def initialize
      @delete_count_by_table = Hash.new { |h, k| h[k] = 0 }
      @update_count_by_table = Hash.new { |h, k| h[k] = 0 }
      @start_time = monotonic_time
    end

    def add_deletions(table, count)
      @delete_count_by_table[table] += count
    end

    def add_updates(table, count)
      @update_count_by_table[table] += count
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
