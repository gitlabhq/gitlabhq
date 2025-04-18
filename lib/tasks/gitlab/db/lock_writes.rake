# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    desc "GitLab | DB | Install prevent write triggers on all databases"
    task lock_writes: [:environment, 'gitlab:db:validate_config'] do
      logger = Logger.new($stdout)
      logger.level = Gitlab::Utils.to_boolean(ENV['VERBOSE']) ? Logger::INFO : Logger::WARN

      options = {}
      options[:scope_to_database] = ENV['SCOPE_TO_DATABASE'] if ENV['SCOPE_TO_DATABASE']

      Gitlab::Database::TablesLocker.new(
        logger: logger,
        dry_run: Gitlab::Utils.to_boolean(ENV['DRY_RUN'], default: false),
        include_partitions: Gitlab::Utils.to_boolean(ENV['INCLUDE_PARTITIONS'], default: true),
        options: options
      ).lock_writes
    end

    desc "GitLab | DB | Remove all triggers that prevents writes from all databases"
    task unlock_writes: :environment do
      logger = Logger.new($stdout)
      logger.level = Gitlab::Utils.to_boolean(ENV['VERBOSE']) ? Logger::INFO : Logger::WARN

      options = {}
      options[:scope_to_database] = ENV['SCOPE_TO_DATABASE'] if ENV['SCOPE_TO_DATABASE']

      Gitlab::Database::TablesLocker.new(
        logger: logger,
        dry_run: Gitlab::Utils.to_boolean(ENV['DRY_RUN'], default: false),
        include_partitions: Gitlab::Utils.to_boolean(ENV['INCLUDE_PARTITIONS'], default: true),
        options: options
      ).unlock_writes
    end
  end
end
