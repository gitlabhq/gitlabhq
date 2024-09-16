# frozen_string_literal: true

module Gitlab
  class BackupLogger
    attr_reader :progress, :json_logger

    def initialize(progress)
      @progress = progress
      @json_logger = ::Gitlab::Backup::JsonLogger.build
    end

    def warn(message)
      progress.puts Rainbow("#{Time.zone.now} -- #{message}").yellow

      json_logger.warn(message: message)
    end

    def info(message)
      progress.puts Rainbow("#{Time.zone.now} -- #{message}").cyan

      json_logger.info(message: message)
    end

    def error(message)
      progress.puts Rainbow("#{Time.zone.now} -- #{message}").red

      json_logger.error(message: message)
    end

    def flush
      progress.flush
    end
  end
end
