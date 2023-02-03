# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    desc "GitLab | DB | Install prevent write triggers on all databases"
    task lock_writes: [:environment, 'gitlab:db:validate_config'] do
      Gitlab::Database::TablesLocker.new(
        logger: Logger.new($stdout),
        dry_run: Gitlab::Utils.to_boolean(ENV['DRY_RUN'], default: false)
      ).lock_writes
    end

    desc "GitLab | DB | Remove all triggers that prevents writes from all databases"
    task unlock_writes: :environment do
      Gitlab::Database::TablesLocker.new(
        logger: Logger.new($stdout),
        dry_run: Gitlab::Utils.to_boolean(ENV['DRY_RUN'], default: false)
      ).unlock_writes
    end
  end
end
