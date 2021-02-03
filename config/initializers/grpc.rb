# frozen_string_literal: true

require 'logger'

GRPC_LOGGER = Logger.new(Rails.root.join('log/grpc.log'))
GRPC_LOGGER.level = ENV['GRPC_LOG_LEVEL'].presence || 'WARN'
GRPC_LOGGER.progname = 'GRPC'

module GRPC
  def self.logger
    GRPC_LOGGER
  end
end
