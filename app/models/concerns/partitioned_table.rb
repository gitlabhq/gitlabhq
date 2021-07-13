# frozen_string_literal: true

module PartitionedTable
  extend ActiveSupport::Concern

  class_methods do
    attr_reader :partitioning_strategy

    PARTITIONING_STRATEGIES = {
      monthly: Gitlab::Database::Partitioning::MonthlyStrategy
    }.freeze

    def partitioned_by(partitioning_key, strategy:, **kwargs)
      strategy_class = PARTITIONING_STRATEGIES[strategy.to_sym] || raise(ArgumentError, "Unknown partitioning strategy: #{strategy}")

      @partitioning_strategy = strategy_class.new(self, partitioning_key, **kwargs)

      Gitlab::Database::Partitioning::PartitionManager.register(self)
    end
  end
end
