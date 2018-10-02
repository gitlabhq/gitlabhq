# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'logger'

module QA
  module Support
    class Logger
      class << self
        delegate :debug, :info, :error, :warn, :fatal, :unknown, to: :logger

        def logger
          return @logger unless @logger.nil?
          @logger = ::Logger.new Runtime::Env.log_destination
          @logger.level = ::Logger::DEBUG
          @logger
        end
      end
    end
  end
end