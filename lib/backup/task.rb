# frozen_string_literal: true

module Backup
  class Task
    # Backup creation and restore option flags
    #
    # @return [Backup::Options]
    attr_reader :options

    def initialize(progress, options:)
      @progress = progress
      @options = options
    end

    # dump task backup to `path`
    #
    # @param [String] path fully qualified backup task destination
    # @param [String] backup_id unique identifier for the backup
    def dump(path, backup_id)
      raise NotImplementedError
    end

    # restore task backup from `path`
    def restore(path, backup_id)
      raise NotImplementedError
    end

    # a string returned here will be displayed to the user before calling #restore
    def pre_restore_warning
    end

    # a string returned here will be displayed to the user after calling #restore
    def post_restore_warning
    end

    private

    attr_reader :progress

    def puts_time(msg)
      progress.puts "#{Time.zone.now} -- #{msg}"
      Gitlab::BackupLogger.info(message: "#{Rainbow.uncolor(msg)}")
    end
  end
end
