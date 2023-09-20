# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresHll
      # For large tables, PostgreSQL can take a long time to count rows due to MVCC.
      # Implements a distinct batch counter based on HyperLogLog algorithm
      # Needs indexes on the column below to calculate max, min and range queries
      # For larger tables just set higher batch_size with index optimization
      #
      # In order to not use a possible complex time consuming query when calculating min and max values,
      # the start and finish can be sent specifically, start and finish should contain max and min values for PRIMARY KEY of
      # relation (most cases `id` column) rather than counted attribute eg:
      # estimate_distinct_count(start: ::Project.aimed_for_deletion.minimum(:id), finish: ::Project.aimed_for_deletion.maximum(:id))
      #
      # Grouped relations are NOT supported yet.
      #
      # @example Usage
      #  ::Gitlab::Database::PostgresHllBatchDistinctCount.new(::Project, :creator_id).execute
      #  ::Gitlab::Database::PostgresHllBatchDistinctCount.new(::Project.aimed_for_deletion.service_desk_enabled.where(time_period))
      #    .execute(
      #      batch_size: 1_000,
      #      start: ::Project.aimed_for_deletion.service_desk_enabled.where(time_period).minimum(:id),
      #      finish: ::Project.aimed_for_deletion.service_desk_enabled.where(time_period).maximum(:id)
      #    )
      #
      # @note HyperLogLog is an PROBABILISTIC algorithm that ESTIMATES distinct count of given attribute value for supplied relation
      #  Like all probabilistic algorithm is has ERROR RATE margin, that can affect values,
      #  for given implementation no higher value was reported (https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45673#accuracy-estimation) than 5.3%
      #  for the most of a cases this value is lower. However, if the exact value is necessary other tools has to be used.
      class BatchDistinctCounter
        ERROR_RATE = 4.9 # max encountered empirical error rate, used in tests
        MIN_REQUIRED_BATCH_SIZE = 750
        SLEEP_TIME_IN_SECONDS = 0.01 # 10 msec sleep
        MAX_DATA_VOLUME = 4_000_000_000

        # Each query should take < 500ms https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
        DEFAULT_BATCH_SIZE = 10_000

        ZERO_OFFSET = 1
        BUCKET_ID_MASK = (Buckets::TOTAL_BUCKETS - ZERO_OFFSET).to_s(2)
        BIT_31_MASK = "B'0#{'1' * 31}'"
        BIT_32_NORMALIZED_BUCKET_ID_MASK = "B'#{'0' * (32 - BUCKET_ID_MASK.size)}#{BUCKET_ID_MASK}'"

        WRONG_CONFIGURATION_ERROR = Class.new(ActiveRecord::StatementInvalid)

        def initialize(relation, column = nil)
          @relation = relation
          @column = column || relation.primary_key
        end

        # Executes counter that iterates over database source and return Gitlab::Database::PostgresHll::Buckets
        # that can be used to estimation of number of uniq elements in analysed set
        #
        # @param batch_size maximal number of rows that will be analysed by single database query
        # @param start initial pkey range
        # @param finish final pkey range
        # @return [Gitlab::Database::PostgresHll::Buckets] HyperLogLog data structure instance that can estimate number of unique elements
        def execute(batch_size: nil, start: nil, finish: nil)
          raise 'BatchCount can not be run inside a transaction' if transaction_open?

          batch_size ||= DEFAULT_BATCH_SIZE
          start = actual_start(start)
          finish = actual_finish(finish)

          raise WRONG_CONFIGURATION_ERROR if unwanted_configuration?(start, finish, batch_size)

          batch_start = start
          hll_buckets = Buckets.new

          while batch_start <= finish
            hll_buckets.merge_hash!(hll_buckets_for_batch(batch_start, batch_start + batch_size))
            batch_start += batch_size
            sleep(SLEEP_TIME_IN_SECONDS)
          end

          hll_buckets
        end

        private

        def transaction_open?
          @relation.connection.transaction_open?
        end

        def unwanted_configuration?(start, finish, batch_size)
          batch_size <= MIN_REQUIRED_BATCH_SIZE ||
            (finish - start) >= MAX_DATA_VOLUME ||
            start > finish || start < 0 || finish < 0
        end

        def hll_buckets_for_batch(start, finish)
          @relation
            .connection
            .execute(bucketed_data_sql % { source_query: source_query(start, finish) })
            .map(&:values)
            .to_h
        end

        # Generate the source query SQL snippet for the provided id range
        #
        # @example SQL query template
        #   SELECT CAST(('X' || md5(CAST(%{column} as text))) as bit(32)) attr_hash_32_bits
        #   FROM %{relation}
        #   WHERE %{pkey} >= %{batch_start} AND %{pkey} < %{batch_end}
        #   AND %{column} IS NOT NULL
        #
        # @param start initial id range
        # @param finish final id range
        # @return [String] SQL query fragment
        def source_query(start, finish)
          col_as_arel = @column.is_a?(Arel::Attributes::Attribute) ? @column : Arel.sql(@column.to_s)
          col_as_text = Arel::Nodes::NamedFunction.new('CAST', [col_as_arel.as('text')])
          md5_of_col = Arel::Nodes::NamedFunction.new('md5', [col_as_text])
          md5_as_hex = Arel::Nodes::Concat.new(Arel.sql("'X'"), md5_of_col)
          bits = Arel::Nodes::NamedFunction.new('CAST', [md5_as_hex.as('bit(32)')])

          @relation
            .where(@relation.primary_key => (start...finish))
            .where(col_as_arel.not_eq(nil))
            .select(bits.as('attr_hash_32_bits')).to_sql
        end

        def actual_start(start)
          start || @relation.unscope(:group, :having).minimum(@relation.primary_key) || 0
        end

        def actual_finish(finish)
          finish || @relation.unscope(:group, :having).maximum(@relation.primary_key) || 0
        end

        # @example source_query
        #   SELECT CAST(('X' || md5(CAST(%{column} as text))) as bit(32)) attr_hash_32_bits
        #   FROM %{relation}
        #   WHERE %{pkey} >= %{batch_start}
        #   AND %{pkey} < %{batch_end}
        #   AND %{column} IS NOT NULL
        def bucketed_data_sql
          <<~SQL
            WITH hashed_attributes AS MATERIALIZED (%{source_query})
            SELECT (attr_hash_32_bits & #{BIT_32_NORMALIZED_BUCKET_ID_MASK})::int AS bucket_num,
              (31 - floor(log(2, min((attr_hash_32_bits & #{BIT_31_MASK})::int))))::int as bucket_hash
            FROM hashed_attributes
            GROUP BY 1
          SQL
        end
      end
    end
  end
end
