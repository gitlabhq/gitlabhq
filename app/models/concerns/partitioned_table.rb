# frozen_string_literal: true

module PartitionedTable
  extend ActiveSupport::Concern

  class_methods do
    attr_reader :partitioning_strategy

    PARTITIONING_STRATEGIES = {
      daily: Gitlab::Database::Partitioning::Time::DailyStrategy,
      monthly: Gitlab::Database::Partitioning::Time::MonthlyStrategy,
      sliding_list: Gitlab::Database::Partitioning::SlidingListStrategy,
      ci_sliding_list: Gitlab::Database::Partitioning::CiSlidingListStrategy,
      int_range: Gitlab::Database::Partitioning::IntRangeStrategy
    }.freeze

    def partitioned_by(partitioning_key, strategy:, **kwargs)
      strategy_class = PARTITIONING_STRATEGIES[strategy.to_sym] || raise(ArgumentError, "Unknown partitioning strategy: #{strategy}")

      @partitioning_strategy = strategy_class.new(self, partitioning_key, **kwargs)
    end

    def with_each_partition
      Gitlab::Database::PostgresPartitionedTable.each_partition(table_name) do |partition|
        yield(from("#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partition.name} AS #{table_name}"))
      end
    end

    # This PR assigns auto populated columns: https://github.com/rails/rails/pull/48241
    # However, a column is identified as auto-populated if it contains default value with nextval function.
    # The id column of partitioned tables is auto-populated via a trigger
    # and it's not identified as an auto-populated column by Rails.
    # Let's explicitly include [primary_key] in a function that expects a list of auto-populated columns
    def _returning_columns_for_insert(...)
      (super + Array(primary_key)).uniq
    end
  end
end
