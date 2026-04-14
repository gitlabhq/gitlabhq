# frozen_string_literal: true

module ActiveContext
  module Databases
    module Concerns
      module Client
        DEFAULT_PREFIX = 'gitlab_active_context'

        attr_reader :options

        def search(_)
          raise NotImplementedError
        end

        private

        def log_search(collection:)
          start_time = Time.current
          result = yield
          duration_s = Time.current - start_time

          ActiveContext::Logger.info(
            message: 'ActiveContext client search completed',
            collection: collection,
            duration_s: duration_s.round(3),
            result_count: result.count
          )

          result
        end
      end
    end
  end
end
