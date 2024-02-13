# frozen_string_literal: true

module ClickHouse
  # rubocop: disable CodeReuse/ActiveRecord -- Building worker-specific ActiveRecord and ClickHouse queries
  class EventAuthorsConsistencyCronWorker
    include ApplicationWorker
    include ClickHouseWorker
    include ClickHouse::Concerns::ConsistencyWorker # defines perform
    include Gitlab::ExclusiveLeaseHelpers

    idempotent!
    queue_namespace :cronjob
    data_consistency :delayed
    worker_has_external_dependencies! # the worker interacts with a ClickHouse database
    feature_category :value_stream_management

    MAX_AUTHOR_DELETIONS = 2000

    private

    def collect_values(ids)
      missing_user_ids_from_batch = missing_user_ids(ids)
      context[:last_processed_id] = missing_user_ids_from_batch.last
      context[:author_records_to_delete].concat(missing_user_ids_from_batch)

      to_be_deleted_size = context[:author_records_to_delete].size
      metadata[:modifications] = to_be_deleted_size

      if to_be_deleted_size >= MAX_AUTHOR_DELETIONS
        metadata[:status] = :limit_reached
        return
      end

      metadata[:status] = :over_time if runtime_limiter.over_time?
    end

    def process_collected_values
      ids = context[:author_records_to_delete]
      query = ClickHouse::Client::Query.new(
        raw_query: 'ALTER TABLE events DELETE WHERE author_id IN ({author_ids:Array(UInt64)})',
        placeholders: { author_ids: ids.to_json }
      )

      connection.execute(query)

      query = ClickHouse::Client::Query.new(
        raw_query: 'ALTER TABLE event_authors DELETE WHERE author_id IN ({author_ids:Array(UInt64)})',
        placeholders: { author_ids: ids.to_json }
      )

      connection.execute(query)
    end

    def init_context
      @context = { author_records_to_delete: [], last_processed_id: 0 }
    end

    def table
      'event_authors'
    end

    def batch_column
      'author_id'
    end

    def pluck_column
      'author_id'
    end

    def missing_user_ids(ids)
      value_list = Arel::Nodes::ValuesList.new(ids.map { |id| [id] })
      User
        .from("(#{value_list.to_sql}) AS user_ids(id)")
        .where('NOT EXISTS (SELECT 1 FROM users WHERE id = user_ids.id)')
        .pluck(:id)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
