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

    # This PR assigns auto populated columns: https://github.com/rails/rails/pull/48241
    # However, a column is identified as auto-populated if it contains default value with nextval function.
    # The id column of partitioned tables is auto-populated via a trigger
    # and it's not identified as an auto-populated column by Rails.
    # Let's explicitly return [primary_key] in a function that expects a list of auto-populated columns
    #
    # Can be removed in Rails 7.2 because it's handled there:
    #
    # https://github.com/rails/rails/blob/v7.2.0.rc1/activerecord/lib/active_record/model_schema.rb#L444
    def _returning_columns_for_insert
      auto_populated_columns = []
      auto_populated_columns = super if Gitlab.next_rails?
      (auto_populated_columns + Array(primary_key)).uniq
    end
  end
end
