# frozen_string_literal: true

# For large tables, PostgreSQL can take a long time to count rows due to MVCC.
# Implements a distinct and ordinary batch counter
# Needs indexes on the column below to calculate max, min and range queries
# For larger tables just set use higher batch_size with index optimization
#
# In order to not use a possible complex time consuming query when calculating min and max for batch_distinct_count
# the start and finish can be sent specifically
#
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
#
# Examples:
#  extend ::Gitlab::Database::BatchCount
#  batch_count(User.active)
#  batch_count(::Clusters::Cluster.aws_installed.enabled, :cluster_id)
#  batch_distinct_count(::Project, :creator_id)
#  batch_distinct_count(::Project.with_active_services.service_desk_enabled.where(time_period), start: ::User.minimum(:id), finish: ::User.maximum(:id))
module Gitlab
  module Database
    module BatchCount
      def batch_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
        BatchCounter.new(relation, column: column).count(batch_size: batch_size, start: start, finish: finish)
      end

      def batch_distinct_count(relation, column = nil, batch_size: nil, start: nil, finish: nil)
        BatchCounter.new(relation, column: column).count(mode: :distinct, batch_size: batch_size, start: start, finish: finish)
      end

      class << self
        include BatchCount
      end
    end

    class BatchCounter
      FALLBACK = -1
      MIN_REQUIRED_BATCH_SIZE = 1_250
      MAX_ALLOWED_LOOPS = 10_000
      SLEEP_TIME_IN_SECONDS = 0.01 # 10 msec sleep
      ALLOWED_MODES = [:itself, :distinct].freeze

      # Each query should take < 500ms https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
      DEFAULT_DISTINCT_BATCH_SIZE = 10_000
      DEFAULT_BATCH_SIZE = 100_000

      def initialize(relation, column: nil)
        @relation = relation
        @column = column || relation.primary_key
      end

      def unwanted_configuration?(finish, batch_size, start)
        batch_size <= MIN_REQUIRED_BATCH_SIZE ||
          (finish - start) / batch_size >= MAX_ALLOWED_LOOPS ||
          start > finish
      end

      def count(batch_size: nil, mode: :itself, start: nil, finish: nil)
        raise 'BatchCount can not be run inside a transaction' if ActiveRecord::Base.connection.transaction_open?

        check_mode!(mode)

        # non-distinct have better performance
        batch_size ||= mode == :distinct ? DEFAULT_DISTINCT_BATCH_SIZE : DEFAULT_BATCH_SIZE

        start = actual_start(start)
        finish = actual_finish(finish)

        raise "Batch counting expects positive values only for #{@column}" if start < 0 || finish < 0
        return FALLBACK if unwanted_configuration?(finish, batch_size, start)

        counter = 0
        batch_start = start

        while batch_start <= finish
          begin
            counter += batch_fetch(batch_start, batch_start + batch_size, mode)
            batch_start += batch_size
          rescue ActiveRecord::QueryCanceled
            # retry with a safe batch size & warmer cache
            if batch_size >= 2 * MIN_REQUIRED_BATCH_SIZE
              batch_size /= 2
            else
              return FALLBACK
            end
          end
          sleep(SLEEP_TIME_IN_SECONDS)
        end

        counter
      end

      def batch_fetch(start, finish, mode)
        # rubocop:disable GitlabSecurity/PublicSend
        @relation.select(@column).public_send(mode).where(between_condition(start, finish)).count
      end

      private

      def between_condition(start, finish)
        return @column.between(start..(finish - 1)) if @column.is_a?(Arel::Attributes::Attribute)

        { @column => start..(finish - 1) }
      end

      def actual_start(start)
        start || @relation.minimum(@column) || 0
      end

      def actual_finish(finish)
        finish || @relation.maximum(@column) || 0
      end

      def check_mode!(mode)
        raise "The mode #{mode.inspect} is not supported" unless ALLOWED_MODES.include?(mode)
        raise 'Use distinct count for optimized distinct counting' if @relation.limit(1).distinct_value.present? && mode != :distinct
        raise 'Use distinct count only with non id fields' if @column == :id && mode == :distinct
      end
    end
  end
end
