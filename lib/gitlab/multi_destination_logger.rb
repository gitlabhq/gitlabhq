# frozen_string_literal: true

module Gitlab
  class MultiDestinationLogger < ::Logger
    def close
      loggers.each(&:close)
    end

    def self.debug(message)
      loggers.each { |logger| logger.build.debug(message) }
    end

    def self.error(message)
      loggers.each { |logger| logger.build.error(message) }
    end

    def self.warn(message)
      loggers.each { |logger| logger.build.warn(message) }
    end

    def self.info(message)
      loggers.each { |logger| logger.build.info(message) }
    end

    def self.read_latest
      primary_logger.read_latest
    end

    def self.file_name
      primary_logger.file_name
    end

    def self.full_log_path
      primary_logger.full_log_path
    end

    def self.file_name_noext
      primary_logger.file_name_noext
    end

    def self.loggers
      raise NotImplementedError
    end

    def self.primary_logger
      raise NotImplementedError
    end
  end
end
