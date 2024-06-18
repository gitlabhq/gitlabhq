# frozen_string_literal: true

module Gitlab
  module Database
    module PostgresHll
      # Bucket class represent data structure build with HyperLogLog algorithm
      # that models data distribution in analysed set. This representation than can be used
      # for following purposes
      #   1. Estimating number of unique elements that this structure represents
      #   2. Merging with other Buckets structure to later estimate number of unique elements in sum of two
      #      represented data sets
      #   3. Serializing Buckets structure to json format, that can be stored in various persistence layers
      #
      # @example Usage
      #  ::Gitlab::Database::PostgresHll::Buckets.new(141 => 1, 56 => 1).estimated_distinct_count
      #  ::Gitlab::Database::PostgresHll::Buckets.new(141 => 1, 56 => 1).merge_hash!(141 => 1, 56 => 5).estimated_distinct_count
      #  ::Gitlab::Database::PostgresHll::Buckets.new(141 => 1, 56 => 1).to_json

      # @note HyperLogLog is an PROBABILISTIC algorithm that ESTIMATES distinct count of given attribute value for supplied relation
      #  Like all probabilistic algorithm is has ERROR RATE margin, that can affect values,
      #  for given implementation no higher value was reported (https://gitlab.com/gitlab-org/gitlab/-/merge_requests/45673#accuracy-estimation) than 5.3%
      #  for the most of a cases this value is lower. However, if the exact value is necessary other tools has to be used.
      class Buckets
        TOTAL_BUCKETS = 512

        def initialize(buckets = {})
          @buckets = buckets
        end

        # Based on HyperLogLog structure estimates number of unique elements in analysed set.
        #
        # @return [Float] Estimate number of unique elements
        def estimated_distinct_count
          @estimated_distinct_count ||= estimate_cardinality
        end

        # Updates instance underlying HyperLogLog structure by merging it with other HyperLogLog structure
        #
        # @param other_buckets_hash hash with HyperLogLog structure representation
        def merge_hash!(other_buckets_hash)
          buckets.merge!(other_buckets_hash) { |_key, old, new| new > old ? new : old }
        end

        # Serialize instance underlying HyperLogLog structure to JSON format, that can be stored in various persistence layers
        #
        # @return [String] HyperLogLog data structure serialized to JSON
        def to_json(_ = nil)
          buckets.to_json
        end

        private

        attr_accessor :buckets

        # arbitrary values that are present in #estimate_cardinality
        # are sourced from https://www.sisense.com/blog/hyperloglog-in-pure-sql/
        # article, they are not representing any entity and serves as tune value
        # for the whole equation
        def estimate_cardinality
          num_zero_buckets = TOTAL_BUCKETS - buckets.size

          num_uniques = (
            ((TOTAL_BUCKETS**2) * (0.7213 / (1 + (1.079 / TOTAL_BUCKETS)))) /
            (num_zero_buckets + buckets.values.sum { |bucket_hash| 2**(-1 * bucket_hash) })
          ).to_i

          if num_zero_buckets > 0 && num_uniques < 2.5 * TOTAL_BUCKETS
            TOTAL_BUCKETS * Math.log(TOTAL_BUCKETS.to_f / num_zero_buckets)
          else
            num_uniques
          end
        end
      end
    end
  end
end
