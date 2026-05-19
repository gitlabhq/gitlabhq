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
  end
end
