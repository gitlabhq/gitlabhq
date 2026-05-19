# frozen_string_literal: true

module Gitlab
  module MergeRequests
    module Mergeability
      class ResultsStore
        def initialize(merge_request:, interface: RedisInterface.new)
          @interface = interface
          @merge_request = merge_request
        end

        def read(merge_check:)
          result_hash = interface.retrieve_check(merge_check: merge_check)

          return if result_hash.blank?

          CheckResult.from_hash(result_hash)
        end

        def write(merge_check:, result_hash:, ttl:)
          interface.save_check(merge_check: merge_check, result_hash: result_hash, ttl: ttl)
        end

        def delete(merge_check:)
          interface.delete_check(cache_key: merge_check.cache_key)
        end

        private

        attr_reader :interface
      end
    end
  end
end
