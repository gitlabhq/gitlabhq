# frozen_string_literal: true

module Gitlab
  module Cleanup
    class OrphanJobArtifactFiles
      include Gitlab::Utils::StrongMemoize

      ABSOLUTE_ARTIFACT_DIR = ::JobArtifactUploader.root.freeze
      LOST_AND_FOUND = File.join(ABSOLUTE_ARTIFACT_DIR, '-', 'lost+found').freeze
      BATCH_SIZE = 500
      DEFAULT_NICENESS = 'best-effort'
      VALID_NICENESS_LEVELS = %w{none realtime best-effort idle}.freeze

      attr_accessor :batch, :total_found, :total_cleaned
      attr_reader :limit, :dry_run, :niceness, :logger

      def initialize(limit: nil, dry_run: true, niceness: nil, logger: nil)
        @limit = limit
        @dry_run = dry_run
        @niceness = (niceness || DEFAULT_NICENESS).downcase
        @logger = logger || Rails.logger # rubocop:disable Gitlab/RailsLogger
        @total_found = @total_cleaned = 0

        new_batch!
      end

      def run!
        log_info('Looking for orphan job artifacts to clean up')

        find_artifacts do |artifact_file|
          batch << artifact_file

          clean_batch! if batch.full?
          break if limit_reached?
        end

        clean_batch!

        log_info("Processed #{total_found} job artifact(s) to find and cleaned #{total_cleaned} orphan(s).")
      end

      private

      def new_batch!
        self.batch = ::Gitlab::Cleanup::OrphanJobArtifactFilesBatch
          .new(batch_size: batch_size, logger: logger, dry_run: dry_run)
      end

      def clean_batch!
        batch.clean!

        update_stats!(batch)

        new_batch!
      end

      def update_stats!(batch)
        self.total_found += batch.artifact_files.count
        self.total_cleaned += batch.lost_and_found.count
      end

      def limit_reached?
        return false unless limit

        total_cleaned >= limit
      end

      def batch_size
        return BATCH_SIZE unless limit
        return if limit_reached?

        todo = limit - total_cleaned
        [BATCH_SIZE, todo].min
      end

      def find_artifacts
        Open3.popen3(*find_command) do |stdin, stdout, stderr, status_thread|
          stdout.each_line do |line|
            yield line.chomp
          end

          log_error(stderr.read.color(:red)) unless status_thread.value.success?
        end
      end

      def find_command
        strong_memoize(:find_command) do
          cmd = %W[find -L #{absolute_artifact_dir}]

          # Search for Job Artifact IDs, they are found 6 directory
          # levels deep. For example:
          # shared/artifacts/2c/62/2c...a3/2019_02_27/836/628/job.log
          #                  1  2  3       4          5   6
          #                  |  |  |       ^- date    |   ^- Job Artifact ID
          #                  |  |  |                  ^- Job ID
          #                  ^--+--+- components of hashed storage project path
          cmd += %w[-mindepth 6 -maxdepth 6]

          # Artifact directories are named on their ID
          cmd += %w[-type d]

          if ionice
            raise ArgumentError, 'Invalid niceness' unless VALID_NICENESS_LEVELS.include?(niceness)

            cmd.unshift(*%W[#{ionice} --class #{niceness}])
          end

          log_info("find command: '#{cmd.join(' ')}'")

          cmd
        end
      end

      def absolute_artifact_dir
        File.absolute_path(ABSOLUTE_ARTIFACT_DIR)
      end

      def ionice
        strong_memoize(:ionice) do
          Gitlab::Utils.which('ionice')
        end
      end

      def log_info(msg, params = {})
        logger.info("#{'[DRY RUN]' if dry_run} #{msg}")
      end

      def log_error(msg, params = {})
        logger.error(msg)
      end
    end
  end
end

Gitlab::Cleanup::OrphanJobArtifactFiles.prepend_if_ee('EE::Gitlab::Cleanup::OrphanJobArtifactFiles')
