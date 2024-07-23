# frozen_string_literal: true

module Gitlab
  class BackupLogger < Gitlab::JsonLogger
    exclude_context!

    attr_reader :progress

    def initialize(progress)
      @progress = progress
    end

    def warn(message)
      progress.puts Rainbow("#{Time.zone.now} -- #{message}").yellow

      super
    end

    def info(message)
      progress.puts Rainbow("#{Time.zone.now} -- #{message}").cyan

      super
    end

    def error(message)
      progress.puts Rainbow("#{Time.zone.now} -- #{message}").red

      super
    end

    def flush
      progress.flush
    end

    def self.file_name_noext
      'backup_json'
    end
  end
end
