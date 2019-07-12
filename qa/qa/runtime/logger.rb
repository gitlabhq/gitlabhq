# frozen_string_literal: true

require 'logger'
require 'forwardable'

module QA
  module Runtime
    module Logger
      extend SingleForwardable

      def_delegators :logger, :debug, :info, :warn, :error, :fatal, :unknown

      singleton_class.module_eval do
        attr_writer :logger

        def logger
          return @logger if @logger

          @logger = ::Logger.new Runtime::Env.log_destination
          @logger.level = Runtime::Env.debug? ? ::Logger::DEBUG : ::Logger::ERROR
          @logger
        end
      end
    end
  end
end
