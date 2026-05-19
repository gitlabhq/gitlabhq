# frozen_string_literal: true

require 'logger'

module Gitlab
  module PoolRepositories
    module RakeTask
      def self.logger
        if Rails.env.development? || Rails.env.production?
          stdout_logger = Logger.new($stdout)
          stdout_logger.level = Logger::INFO
          ActiveSupport::BroadcastLogger.new(stdout_logger, Rails.logger)
        else
          Rails.logger
        end
      end
    end
  end
end
