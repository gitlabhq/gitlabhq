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
            source: 'QA Tests',
            path: File.expand_path('../../tmp', __dir__)
          )
        end

        delegate :debug, :info, :warn, :error, :fatal, :unknown, to: :logger
      end
    end
  end
end
