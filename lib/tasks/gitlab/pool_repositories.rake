# frozen_string_literal: true

namespace :gitlab do
  namespace :pool_repositories do
    desc 'GitLab | Pool Repositories | Discover orphaned pool repositories using Gitaly RPCs'
    task discover_orphaned: :gitlab_environment do
      warn_user_is_not_gitlab

      output_file = ENV['OUTPUT_FILE']
      verbose = ENV['VERBOSE'] == 'true'
      logger = Gitlab::PoolRepositories::RakeTask.logger

      if output_file.blank?
        logger.error Rainbow('ERROR: OUTPUT_FILE environment variable is required').red
        logger.info 'Usage: bin/rake gitlab:pool_repositories:discover_orphaned OUTPUT_FILE=/path/to/output.csv'
        exit 1
      end

      discoverer = Gitlab::PoolRepositories::OrphanedDiscoverer.new(
        logger: logger,
        output_file: output_file,
        verbose: verbose
      )

      discoverer.run!

      logger.info Rainbow("Discovery complete. Results saved to #{output_file}").green
    end

    desc 'GitLab | Pool Repositories | Clean up orphaned pool repository records on decommissioned shards'
    task cleanup_orphaned_on_missing_shards: :gitlab_environment do
      warn_user_is_not_gitlab

      shard_names = ENV['SHARD_NAMES'].to_s.split(',')
      output_file = ENV['OUTPUT_FILE']
      dry_run = ENV['DRY_RUN'] != 'false'
      logger = Gitlab::PoolRepositories::RakeTask.logger

      if shard_names.empty? || output_file.blank?
        logger.error Rainbow('ERROR: SHARD_NAMES and OUTPUT_FILE environment variables are required').red
        logger.info 'Usage: bin/rake gitlab:pool_repositories:cleanup_orphaned_on_missing_shards ' \
          'SHARD_NAMES=shard1,shard2 OUTPUT_FILE=/path/to/output.csv [DRY_RUN=false]'
        exit 1
      end

      begin
        cleaner = Gitlab::PoolRepositories::MissingShardCleaner.new(
          shard_names: shard_names,
          output_file: output_file,
          logger: logger,
          dry_run: dry_run
        )

        cleaner.run!
      rescue Gitlab::PoolRepositories::MissingShardCleaner::ValidationError => e
        logger.error Rainbow("ERROR: #{e.message}").red
        exit 1
      end

      logger.info Rainbow("Results saved to #{output_file}").green

      logger.info Rainbow('To delete these records run this command with DRY_RUN=false').yellow if dry_run
    end

    desc 'GitLab | Pool Repositories | Classify member projects of sourceless pools on decommissioned shards'
    task classify_dead_shard_members: :gitlab_environment do
      warn_user_is_not_gitlab

      shard_names = ENV['SHARD_NAMES'].to_s.split(',')
      output_file = ENV['OUTPUT_FILE']
      logger = Gitlab::PoolRepositories::RakeTask.logger

      if shard_names.empty? || output_file.blank?
        logger.error Rainbow('ERROR: SHARD_NAMES and OUTPUT_FILE environment variables are required').red
        logger.info 'Usage: bin/rake gitlab:pool_repositories:classify_dead_shard_members ' \
          'SHARD_NAMES=shard1,shard2 OUTPUT_FILE=/path/to/output.csv'
        exit 1
      end

      begin
        classifier = Gitlab::PoolRepositories::MissingShardClassifier.new(
          shard_names: shard_names,
          logger: logger,
          output_file: output_file
        )

        classifier.run!
      rescue Gitlab::PoolRepositories::MissingShardClassifier::ValidationError => e
        logger.error Rainbow("ERROR: #{e.message}").red
        exit 1
      end

      logger.info Rainbow("Classification complete. Results saved to #{output_file}").green
    end
  end
end
