# frozen_string_literal: true

require 'forwardable'

module QA
  module Runtime
    class Logger
      extend SingleForwardable

      def_delegators :logger, :debug, :info, :warn, :error, :fatal, :unknown

      # Global logger instance
      #
      # @return [ActiveSupport::Logger]
      def self.logger
        @logger ||= Gitlab::QA::TestLogger.logger(
          level: Gitlab::QA::Runtime::Env.log_level,
          source: 'QA Tests',
          path: File.expand_path('../../tmp', __dir__)
        )
      end
    end
  end
end
