# frozen_string_literal: true

module Geo
  class PruneEventLogService
    include ::Gitlab::Geo::LogHelpers
    include ::ExclusiveLeaseGuard

    TOTAL_LIMIT = 50_000
    LEASE_TIMEOUT = 4.minutes

    attr_reader :event_log_min_id

    def initialize(event_log_min_id)
      @event_log_min_id = event_log_min_id
    end

    def execute
      return if Gitlab::Database.read_only?

      try_obtain_lease do
        log_info('Prune Geo Event Log entries up to id', geo_event_log_id: event_log_min_id)

        prunable_relations.reduce(TOTAL_LIMIT) do |limit, relation|
          break if limit <= 0
          break unless renew_lease!

          limit - prune!(relation, limit).to_i
        end
      end
    end

    private

    def lease_timeout
      LEASE_TIMEOUT
    end

    def prunable_relations
      Geo::EventLog.event_classes
    end

    def prune!(relation, limit)
      unless delete_all?
        relation = relation.up_to_event(event_log_min_id)
      end

      deleted = relation.delete_with_limit(limit)

      if deleted.positive?
        log_info('Rows pruned from Geo Event log',
                 relation: relation.name,
                 rows_deleted: deleted,
                 limit: limit)
      end

      deleted
    end

    def delete_all?
      event_log_min_id == :all
    end
  end
end
