# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module GitalyTimeout
        TIMEOUT_KEY = 'ci_config_gitaly_timeout'

        class << self
          def with_timeout(timeout)
            previous = Thread.current[TIMEOUT_KEY]
            Thread.current[TIMEOUT_KEY] = timeout
            yield
          ensure
            Thread.current[TIMEOUT_KEY] = previous
          end

          def current_timeout
            Thread.current[TIMEOUT_KEY]
          end
        end
      end
    end
  end
end
