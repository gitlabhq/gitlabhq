# frozen_string_literal: true

module Gitlab
  module Database
    # For large tables, PostgreSQL can take a long time to count rows due to MVCC.
    # Implements a distinct batch counter based on HyperLogLog algorithm
    # Needs indexes on the column below to calculate max, min and range queries
    # For larger tables just set higher batch_size with index optimization
    #
    # In order to not use a possible complex time consuming query when calculating min and max values,
    # the start and finish can be sent specifically, start and finish should contain max and min values for PRIMARY KEY of
    # relation (most cases `id` column) rather than counted attribute eg:
    # estimate_distinct_count(start: ::Project.with_active_services.minimum(:id), finish: ::Project.with_active_services.maximum(:id))
    #
    # Grouped relations are NOT supported yet.
    #
    # @example Usage
    #  ::Gitlab::Database::PostgresHllBatchDistinctCount.new(::Project, :creator_id).estimate_distinct_count
    #  ::Gitlab::Database::PostgresHllBatchDistinctCount.new(::Project.with_active_services.service_desk_enabled.where(time_period))
    #    .estimate_distinct_count(
    #      batch_size: 1_000,
    #      start: ::Project.with_active_services.service_desk_enabled.where(time_period).minimum(:id),
    #      finish: ::Project.with_active_services.service_desk_enabled.where(time_period).maximum(:id)
    #    )
    #
    # @note HyperLogLog is an PROBABILISTIC algorithm that ESTIMATES distinct count of given attribute value for supplied relation
    #  Like all probabilistic algorithm is has ERROR RATE margin, that can affect values,
    #  for given implementation no higher value was reported (https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45673#accuracy-estimation) than 5.3%
    #  for the most of a cases this value is lower. However, if the exact value is necessary other tools has to be used.
    class PostgresHllBatchDistinctCounter
      FALLBACK = -1
      MIN_REQUIRED_BATCH_SIZE = 1_250
      MAX_ALLOWED_LOOPS = 10_000
      SLEEP_TIME_IN_SECONDS = 0.01 # 10 msec sleep

      # Each query should take < 500ms https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
      DEFAULT_BATCH_SIZE = 100_000

      BIT_31_MASK = "B'0#{'1' * 31}'"
      BIT_9_MASK = "B'#{'0' * 23}#{'1' * 9}'"
      # @example source_query
      #   SELECT CAST(('X' || md5(CAST(%{column} as text))) as bit(32)) attr_hash_32_bits
      #   FROM %{relation}
      #   WHERE %{pkey} >= %{batch_start}
      #   AND %{pkey} < %{batch_end}
      #   AND %{column} IS NOT NULL
      BUCKETED_DATA_SQL = <<~SQL
        WITH hashed_attributes AS (%{source_query})
        SELECT (attr_hash_32_bits & #{BIT_9_MASK})::int AS bucket_num,
          (31 - floor(log(2, min((attr_hash_32_bits & #{BIT_31_MASK})::int))))::int as bucket_hash
        FROM hashed_attributes
        GROUP BY 1 ORDER BY 1
      SQL

      TOTAL_BUCKETS_NUMBER = 512

      def initialize(relation, column = nil)
        @relation = relation
        @column = column || relation.primary_key
      end

      def unwanted_configuration?(finish, batch_size, start)
        batch_size <= MIN_REQUIRED_BATCH_SIZE ||
          (finish - start) / batch_size >= MAX_ALLOWED_LOOPS ||
          start > finish
      end

      def estimate_distinct_count(batch_size: nil, start: nil, finish: nil)
        raise 'BatchCount can not be run inside a transaction' if ActiveRecord::Base.connection.transaction_open?

        batch_size ||= DEFAULT_BATCH_SIZE

        start = actual_start(start)
        finish = actual_finish(finish)

        raise "Batch counting expects positive values only for #{@column}" if start < 0 || finish < 0
        return FALLBACK if unwanted_configuration?(finish, batch_size, start)

        batch_start = start
        hll_blob = {}

        while batch_start <= finish
          begin
            hll_blob.merge!(hll_blob_for_batch(batch_start, batch_start + batch_size)) {|_key, old, new| new > old ? new : old }
            batch_start += batch_size
          end
          sleep(SLEEP_TIME_IN_SECONDS)
        end

        estimate_cardinality(hll_blob)
      end

      private

      # arbitrary values that are present in #estimate_cardinality
      # are sourced from https://www.sisense.com/blog/hyperloglog-in-pure-sql/
      # article, they are not representing any entity and serves as tune value
      # for the whole equation
      def estimate_cardinality(hll_blob)
        num_zero_buckets = TOTAL_BUCKETS_NUMBER - hll_blob.size

        num_uniques = (
          ((TOTAL_BUCKETS_NUMBER**2) * (0.7213 / (1 + 1.079 / TOTAL_BUCKETS_NUMBER))) /
            (num_zero_buckets + hll_blob.values.sum { |bucket_hash, _| 2**(-1 * bucket_hash)} )
        ).to_i

        if num_zero_buckets > 0 && num_uniques < 2.5 * TOTAL_BUCKETS_NUMBER
          ((0.7213 / (1 + 1.079 / TOTAL_BUCKETS_NUMBER)) * (TOTAL_BUCKETS_NUMBER *
            Math.log2(TOTAL_BUCKETS_NUMBER.to_f / num_zero_buckets)))
        else
          num_uniques
        end
      end

      def hll_blob_for_batch(start, finish)
        @relation
          .connection
          .execute(BUCKETED_DATA_SQL % { source_query: source_query(start, finish) })
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
    end
  end
end
