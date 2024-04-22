# frozen_string_literal: true

module Gitlab
  class BackupLogger < Gitlab::JsonLogger
    exclude_context!

    attr_reader :progress

    def initialize(progress)
      @progress = progress
    end

    def warn(message)
      progress.puts "#{Time.zone.now} -- #{message}".color(:yellow)

      super
    end

    def info(message)
      progress.puts "#{Time.zone.now} -- #{message}".color(:cyan)

      super
    end

    def error(message)
      progress.puts "#{Time.zone.now} -- #{message}".color(:red)

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
