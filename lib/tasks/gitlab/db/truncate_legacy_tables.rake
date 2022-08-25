# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    namespace :truncate_legacy_tables do
      desc "GitLab | DB | Truncate CI Tables on Main"
      task :main, [:min_batch_size] => [:environment, 'gitlab:db:validate_config'] do |_t, args|
        args.with_defaults(min_batch_size: 5)
        Gitlab::Database::TablesTruncate.new(
          database_name: 'main',
          min_batch_size: args.min_batch_size.to_i,
          logger: Logger.new($stdout),
          dry_run: ENV['DRY_RUN'] == 'true',
          until_table: ENV['UNTIL_TABLE']
        ).execute
      end

      desc "GitLab | DB | Truncate Main Tables on CI"
      task :ci, [:min_batch_size] => [:environment, 'gitlab:db:validate_config'] do |_t, args|
        args.with_defaults(min_batch_size: 5)
        Gitlab::Database::TablesTruncate.new(
          database_name: 'ci',
          min_batch_size: args.min_batch_size.to_i,
          logger: Logger.new($stdout),
          dry_run: ENV['DRY_RUN'] == 'true',
          until_table: ENV['UNTIL_TABLE']
        ).execute
      end
    end
  end
end
