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
          @logger ||= ::Logger.new(Runtime::Env.log_destination).tap do |logger|
            logger.level = Runtime::Env.debug? ? ::Logger::DEBUG : ::Logger::ERROR
          end
        end
      end
    end
  end
end
