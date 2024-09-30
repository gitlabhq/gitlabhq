# frozen_string_literal: true

module QA
  module Runtime
    class Logger
      class << self
        # Global logger instance
        #
        # @return [ActiveSupport::Logger]
        def logger
          @logger ||= Gitlab::QA::TestLogger.logger(
            level: Gitlab::QA::Runtime::Env.log_level,
            source: logger_source,
            path: log_path
          )
        end

        delegate :debug, :info, :warn, :error, :fatal, :unknown, to: :logger

        private

        def logger_source
          if ENV['TEST_ENV_NUMBER']
            "QA Tests ENV-#{ENV['TEST_ENV_NUMBER']}"
          else
            "QA Tests"
          end
        end

        def log_path
          File.expand_path('../../tmp', __dir__)
        end
      end
    end
  end
end
