# frozen_string_literal: true

require 'logger'

module QA
  module Runtime
    module Logger
      extend SingleForwardable

      def_delegators :logger, :debug, :info, :error, :warn, :fatal, :unknown

      singleton_class.module_eval do
        def logger
          return @logger if @logger

          @logger = ::Logger.new Runtime::Env.log_destination
          @logger.level = ::Logger::DEBUG
          @logger
        end
      end
    end
  end
end
