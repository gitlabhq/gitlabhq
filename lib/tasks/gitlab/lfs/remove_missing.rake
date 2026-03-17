# frozen_string_literal: true

namespace :gitlab do
  namespace :lfs do
    desc 'GitLab | LFS | Remove LFS objects with missing files from the database'
    task remove_missing: :gitlab_environment do
      warn_user_is_not_gitlab

      dry_run = ENV['DRY_RUN'] != 'false'

      logger = if Rails.env.development? || Rails.env.production?
                 stdout_logger = Logger.new($stdout)
                 stdout_logger.level = Logger::INFO
                 ActiveSupport::BroadcastLogger.new(stdout_logger, Rails.logger)
               else
                 Rails.logger
               end

      # Log execution parameters
      logger.info("Running gitlab:lfs:remove_missing")
      logger.info("  DRY_RUN=#{dry_run} (set DRY_RUN=false to actually delete)")

      # Require confirmation for non-dry-run execution
      unless dry_run
        puts Rainbow("WARNING: This will delete LFS objects server-wide. Type 'yes' to continue:").yellow
        exit 1 unless $stdin.gets&.chomp == 'yes'
      end

      cleaner = Gitlab::Cleanup::OrphanLfsObjects.new(
        dry_run: dry_run,
        logger: logger
      )

      cleaner.run!
    end
  end
end
