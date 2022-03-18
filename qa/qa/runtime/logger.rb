# frozen_string_literal: true

require 'forwardable'

module QA
  module Runtime
    class Logger
      extend SingleForwardable

      def_delegators :logger, :debug, :info, :warn, :error, :fatal, :unknown

      def self.logger
        @logger ||= Gitlab::QA::TestLogger.logger(
          level: Runtime::Env.debug? ? ::Logger::DEBUG : ::Logger::INFO,
          source: 'QA Tests'
        )
      end
    end
  end
end
