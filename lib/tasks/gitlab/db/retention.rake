# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    namespace :retention do
      desc 'GitLab | DB | Regenerate the retention policy allowlist'
      task generate_allowlist: %i[environment] do
        path = Rails.root.join('spec/support/database/retention-policy-missing-allowlist.yml')

        header = <<~HEADER
          # Tables that do not yet declare a retention policy under db/docs/data_retention/.
          #
          # Consumed by spec/db/retention_policy_definitions_spec.rb. Every table listed
          # here is temporarily exempt from the retention policy requirement. This list must
          # only shrink: once a table declares a retention policy, remove it from this file.
          # New tables must declare a retention policy rather than being added here.
          #
          # Kept next to spec/support/database/cross-join-allowlist.yml and
          # cross-database-modification-allowlist.yml, which follow the same grandfathering
          # pattern for database-level rules.
          #
          # Regenerate the baseline with:
          #   bundle exec rake gitlab:db:retention:generate_allowlist
        HEADER

        tables = Gitlab::Database::RetentionPolicy.eligible_tables.filter_map do |table|
          table.table_name unless Rails.root.join('db', 'docs', 'data_retention', "#{table.table_name}.yml").exist?
        end.uniq.sort

        File.write(path, "#{header}#{tables.to_yaml}")

        puts "Wrote #{tables.size} tables to #{path.relative_path_from(Rails.root)}."
      end
    end
  end
end
