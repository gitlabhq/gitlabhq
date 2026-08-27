# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    # Exits 1 on any error finding. Deliberately a plain 0/1 contract, unlike
    # gitlab:db:validate_schema, whose 0/1/2 the omnibus upgrade gate consumes.
    desc 'GitLab | DB | Report database diagnostics on the console'
    task :diagnostics, [:database_names] => :environment do |_, args|
      # Rake splits `[main,ci]` on commas, so later names land in `extras`.
      requested = [args[:database_names], *args.extras].compact.map(&:strip).reject(&:empty?)

      valid_names = Gitlab::Database.database_base_models.keys
      unknown = requested - valid_names
      abort("Unknown database(s): #{unknown.join(', ')}. Valid: #{valid_names.join(', ')}.") if unknown.any?

      # Skip shared connections, or a single-cluster install reports the same database repeatedly.
      database_names = requested.presence || Gitlab::Database.database_base_models
        .reject { |_, model| Gitlab::Database.db_config_share_with(model.connection_db_config) }
        .keys

      result = Gitlab::Database::Diagnostics::Console.run(database_names: database_names)

      if result == Gitlab::Database::Diagnostics::Findings::ERROR
        abort('Database diagnostics found errors. Review the output above.')
      end
    end
  end
end
