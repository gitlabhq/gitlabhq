# frozen_string_literal: true

module Ci
  module ClickHouse
    module DataIngestion
      class FinishedPipelinesSyncService
        include Gitlab::ExclusiveLeaseHelpers
        include Gitlab::Utils::StrongMemoize

        # the job is scheduled every 3 minutes and we will allow maximum 6 minutes runtime
        # we must allow a minimum of 2 minutes + 15 seconds PG timeout + 1 minute for the various
        # CH Gitlab::HTTP timeouts
        MAX_TTL = 6.minutes.to_i
        MAX_RUNTIME = 120.seconds
        PIPELINES_BATCH_SIZE = 500
        PIPELINES_BATCH_COUNT = 10 # How many batches to process before submitting the CSV to ClickHouse
        PIPELINE_ID_PARTITIONS = 100

        PIPELINE_FIELD_NAMES = %i[id duration status source ref].freeze
        PIPELINE_EPOCH_FIELD_NAMES = %i[committed_at created_at started_at finished_at].freeze
        PIPELINE_COMPUTED_FIELD_NAMES = %i[path].freeze

        CSV_MAPPING = {
          **PIPELINE_FIELD_NAMES.index_with { |n| n },
          **PIPELINE_EPOCH_FIELD_NAMES.index_with { |n| :"casted_#{n}" },
          **PIPELINE_COMPUTED_FIELD_NAMES.index_with { |n| n }
        }.freeze

        INSERT_FINISHED_PIPELINES_QUERY = <<~SQL.squish
          INSERT INTO ci_finished_pipelines (#{CSV_MAPPING.keys.join(',')})
          SETTINGS async_insert=1, wait_for_async_insert=1 FORMAT CSV
        SQL

        def self.enabled?
          ::Gitlab::ClickHouse.configured?
        end

        def initialize(worker_index: 0, total_workers: 1)
          @runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)
          @worker_index = worker_index
          @total_workers = total_workers
        end

        def execute
          unless self.class.enabled?
            return ServiceResponse.error(
              message: 'Disabled: ClickHouse database is not configured.',
              reason: :db_not_configured,
              payload: service_payload
            )
          end

          # Prevent parallel jobs
          in_lock("#{self.class.name.underscore}/worker/#{@worker_index}", ttl: MAX_TTL, retries: 0) do
            ::Gitlab::Database::LoadBalancing::SessionMap.without_sticky_writes do
              report = insert_new_finished_pipelines

              ServiceResponse.success(payload: report.merge(service_payload))
            end
          end
        rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError => e
          # Skip retrying, just let the next worker to start after a few minutes
          ServiceResponse.error(message: e.message, reason: :skipped, payload: service_payload)
        end

        private

        def continue?
          !@reached_end_of_table && !@runtime_limiter.over_time?
        end

        def service_payload
          {
            worker_index: @worker_index,
            total_workers: @total_workers
          }
        end

        def insert_new_finished_pipelines
          # Read PIPELINES_BATCH_COUNT batches of PIPELINES_BATCH_SIZE until the timeout in MAX_RUNTIME is reached
          # We can expect a single worker to process around 2M pipelines/hour with a single worker,
          # and a bit over 5M pipelines/hour with three workers (measured in prod).
          @reached_end_of_table = false
          @processed_record_ids = []

          csv_batches.each do |csv_batch|
            break unless continue?

            csv_builder = CsvBuilder::Gzip.new(csv_batch, CSV_MAPPING)
            csv_builder.render do |tempfile|
              next if csv_builder.rows_written == 0

              File.open(tempfile.path) do |f|
                ::ClickHouse::Client.insert_csv(INSERT_FINISHED_PIPELINES_QUERY, f, :main)
              end
            end
          end

          {
            records_inserted:
              Ci::FinishedPipelineChSyncEvent.primary_key_in(@processed_record_ids).update_all(processed: true),
            reached_end_of_table: @reached_end_of_table
          }
        end

        def csv_batches
          events_batches_enumerator = Enumerator.new do |small_batches_yielder|
            # Main loop to page through the events
            keyset_iterator_scope.each_batch(of: PIPELINES_BATCH_SIZE) { |batch| small_batches_yielder << batch }
            @reached_end_of_table = true
          end

          Enumerator.new do |batches_yielder|
            # Each batches_yielder value represents a CSV file upload
            while continue?
              batches_yielder << Enumerator.new do |records_yielder|
                # records_yielder sends rows to the CSV builder
                PIPELINES_BATCH_COUNT.times do
                  break unless continue?

                  yield_pipelines(events_batches_enumerator.next, records_yielder)

                rescue StopIteration
                  break
                end
              end
            end
          end
        end

        def yield_pipelines(events_batch, records_yielder)
          # NOTE: The `.to_a` call is necessary here to materialize the ActiveRecord relationship, so that the call
          # to `.last` in `.each_batch` (see https://gitlab.com/gitlab-org/gitlab/-/blob/a38c93c792cc0d2536018ed464862076acb8d3d7/lib/gitlab/pagination/keyset/iterator.rb#L27)
          # doesn't mess it up and cause duplicates (see https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138066)
          # rubocop: disable CodeReuse/ActiveRecord -- this is an expression that is specific to this service
          # rubocop: disable Database/AvoidUsingPluckWithoutLimit -- the batch is already limited by definition
          events_batch = events_batch.to_a
          pipeline_ids = events_batch.pluck(:pipeline_id)
          project_namespace_ids = events_batch.pluck(:pipeline_id, :project_namespace_id).to_h
          # rubocop: enable Database/AvoidUsingPluckWithoutLimit
          # rubocop: enable CodeReuse/ActiveRecord

          pipelines = Ci::Pipeline.id_in(pipeline_ids)
          pipelines
            .left_outer_joins(project_mirror: :namespace_mirror)
            .select(:finished_at, *finished_pipeline_projections)
            .each do |pipeline|
              records_yielder << pipeline.attributes.symbolize_keys.tap do |record|
                # add the project namespace ID segment to the path selected in the query
                record[:path] += "#{project_namespace_ids[record[:id]]}/"
                record[:duration] = 0 if record[:duration].nil? || record[:duration] < 0
              end
            end

          @processed_record_ids += pipeline_ids
        end

        def finished_pipeline_projections
          [
            *PIPELINE_FIELD_NAMES.map { |n| "#{::Ci::Pipeline.table_name}.#{n}" },
            *PIPELINE_EPOCH_FIELD_NAMES
               .map { |n| "COALESCE(EXTRACT(epoch FROM #{::Ci::Pipeline.table_name}.#{n}), 0) AS casted_#{n}" },
            "ARRAY_TO_STRING(#{::Ci::NamespaceMirror.table_name}.traversal_ids, '/') || '/' AS path"
          ]
        end
        strong_memoize_attr :finished_pipeline_projections

        def keyset_iterator_scope
          lower_bound = (@worker_index * PIPELINE_ID_PARTITIONS / @total_workers).to_i
          upper_bound = ((@worker_index + 1) * PIPELINE_ID_PARTITIONS / @total_workers).to_i - 1

          table_name = Ci::FinishedPipelineChSyncEvent.quoted_table_name
          array_scope = Ci::FinishedPipelineChSyncEvent.select(:pipeline_id_partition)
            .from("generate_series(#{lower_bound}, #{upper_bound}) as #{table_name}(pipeline_id_partition)") # rubocop: disable CodeReuse/ActiveRecord -- this is an expression that is specific to this service

          opts = {
            in_operator_optimization_options: {
              array_scope: array_scope,
              array_mapping_scope: ->(id_expression) do
                Ci::FinishedPipelineChSyncEvent
                  .where(Arel.sql("(pipeline_id % #{PIPELINE_ID_PARTITIONS})") # rubocop: disable CodeReuse/ActiveRecord -- this is an expression that is specific to this service
                    .eq(id_expression))
              end
            }
          }

          Gitlab::Pagination::Keyset::Iterator.new(
            scope: Ci::FinishedPipelineChSyncEvent.pending.order_by_pipeline_id, **opts)
        end
      end
    end
  end
end
