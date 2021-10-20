# frozen_string_literal: true

# For large tables, PostgreSQL can take a long time to count rows due to MVCC.
# We can optimize this by using various strategies for approximate counting.
#
# For example, we can use the reltuples count as described in https://wiki.postgresql.org/wiki/Slow_Counting.
#
# However, since statistics are not always up to date, we also implement a table sampling strategy
# that performs an exact count but only on a sample of the table. See TablesampleCountStrategy.
module Gitlab
  module Database
    module Count
      CONNECTION_ERRORS =
        if defined?(PG)
          [
            ActionView::Template::Error,
            ActiveRecord::StatementInvalid,
            PG::Error
          ].freeze
        else
          [
            ActionView::Template::Error,
            ActiveRecord::StatementInvalid
          ].freeze
        end

      # Takes in an array of models and returns a Hash for the approximate
      # counts for them.
      #
      # Various count strategies can be specified that are executed in
      # sequence until all tables have an approximate count attached
      # or we run out of strategies.
      #
      # Note that not all strategies are available on all supported RDBMS.
      #
      # @param [Array]
      # @return [Hash] of Model -> count mapping
      def self.approximate_counts(models, strategies: [])
        if strategies.empty?
          # ExactCountStrategy is the only strategy working on read-only DBs, as others make
          # use of tuple stats which use the primary DB to estimate tables size in a transaction.
          strategies = if ::Gitlab::Database.read_write?
                         [TablesampleCountStrategy, ReltuplesCountStrategy, ExactCountStrategy]
                       else
                         [ExactCountStrategy]
                       end
        end

        strategies.each_with_object({}) do |strategy, counts_by_model|
          models_with_missing_counts = models - counts_by_model.keys

          break counts_by_model if models_with_missing_counts.empty?

          counts = strategy.new(models_with_missing_counts).count

          counts.each do |model, count|
            counts_by_model[model] = count
          end
        end
      end
    end
  end
end
