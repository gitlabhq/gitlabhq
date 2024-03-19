# frozen_string_literal: true

module Backup
  module Targets
    class Target
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

      private

      attr_reader :progress

      def puts_time(msg)
        progress.puts "#{Time.zone.now} -- #{msg}"
        Gitlab::BackupLogger.info(message: Rainbow.uncolor(msg).to_s)
      end
    end
  end
end
