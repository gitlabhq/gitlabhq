# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    # Exits 1 on any error finding. Deliberately a plain 0/1 contract, unlike
    # gitlab:db:validate_schema, whose 0/1/2 the omnibus upgrade gate consumes.
    desc 'GitLab | DB | Report database diagnostics on the console'
    task :diagnostics, [:database_names] => :environment do |_, args|
      Gitlab::Database::Diagnostics::RakeTask.run(args)
    end

    namespace :diagnostics do
      # Zeitwerk is not loaded yet, so the Diagnostics::Console::VIEWS registry
      # keys are repeated here. The rake spec fails when the two lists drift.
      %w[search_path autovacuum_settings].each do |check_name|
        desc "GitLab | DB | Report #{check_name.tr('_', ' ')} diagnostics on the console"
        task check_name, [:database_names] => :environment do |_, args|
          Gitlab::Database::Diagnostics::RakeTask.run(args, check_name: check_name)
        end
      end
    end
  end
end
