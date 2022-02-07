# frozen_string_literal: true

require 'logger'
require 'forwardable'
require 'rainbow/refinement'

module QA
  module Runtime
    module Logger
      extend SingleForwardable
      using Rainbow

      def_delegators :logger, :debug, :info, :warn, :error, :fatal, :unknown

      singleton_class.module_eval do
        attr_writer :logger

        def logger
          Rainbow.enabled = Runtime::Env.colorized_logs?

          @logger ||= ::Logger.new(Runtime::Env.log_destination).tap do |logger|
            logger.level = Runtime::Env.debug? ? ::Logger::DEBUG : ::Logger::ERROR

            logger.formatter = proc do |severity, datetime, progname, msg|
              date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")

              "[date=#{date_format} from=QA Tests] #{severity.ljust(5)} -- ".yellow + "#{msg}\n"
            end
          end
        end
      end
    end
  end
end
