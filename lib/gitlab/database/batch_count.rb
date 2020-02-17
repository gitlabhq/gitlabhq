# frozen_string_literal: true

# For large tables, PostgreSQL can take a long time to count rows due to MVCC.
# Implements a distinct and ordinary batch counter
# Needs indexes on the column below to calculate max, min and range queries
# For larger tables just set use higher batch_size with index optimization
# See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
# Examples:
#  extend ::Gitlab::Database::BatchCount
#  batch_count(User.active)
#  batch_count(::Clusters::Cluster.aws_installed.enabled, :cluster_id)
#  batch_distinct_count(::Project, :creator_id)
module Gitlab
  module Database
    module BatchCount
      def batch_count(relation, column = nil, batch_size: nil)
        BatchCounter.new(relation, column: column).count(batch_size: batch_size)
      end

      def batch_distinct_count(relation, column = nil, batch_size: nil)
        BatchCounter.new(relation, column: column).count(mode: :distinct, batch_size: batch_size)
      end

      class << self
        include BatchCount
      end
    end

    class BatchCounter
      FALLBACK = -1
      MIN_REQUIRED_BATCH_SIZE = 2_000
      MAX_ALLOWED_LOOPS = 10_000
      SLEEP_TIME_IN_SECONDS = 0.01 # 10 msec sleep
      # Each query should take <<500ms https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22705
      DEFAULT_DISTINCT_BATCH_SIZE = 100_000
      DEFAULT_BATCH_SIZE = 10_000

      def initialize(relation, column: nil)
        @relation = relation
        @column = column || relation.primary_key
      end

      def unwanted_configuration?(finish, batch_size, start)
        batch_size <= MIN_REQUIRED_BATCH_SIZE ||
          (finish - start) / batch_size >= MAX_ALLOWED_LOOPS ||
          start > finish
      end

      def count(batch_size: nil, mode: :itself)
        raise 'BatchCount can not be run inside a transaction' if ActiveRecord::Base.connection.transaction_open?
        raise "The mode #{mode.inspect} is not supported" unless [:itself, :distinct].include?(mode)

        # non-distinct have better performance
        batch_size ||= mode == :distinct ? DEFAULT_BATCH_SIZE : DEFAULT_DISTINCT_BATCH_SIZE

        start = @relation.minimum(@column) || 0
        finish = @relation.maximum(@column) || 0

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
        @relation.select(@column).public_send(mode).where(@column => start..(finish - 1)).count
      end
    end
  end
end
