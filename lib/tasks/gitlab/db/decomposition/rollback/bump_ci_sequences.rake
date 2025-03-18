# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    namespace :decomposition do
      namespace :rollback do
        desc 'Bump all the CI tables sequences on the Main Database'
        task :bump_ci_sequences, [:increase_by] => :environment do |_t, args|
          increase_by = args.increase_by.to_i
          if increase_by < 1
            puts Rainbow('Please specify a positive integer `increase_by` value').red
            puts Rainbow('Example: rake gitlab:db:decomposition:rollback:bump_ci_sequences[100000]').green
            exit 1
          end

          ci_only_schemas = Gitlab::Database
            .all_database_connections["main"]
            .lock_gitlab_schemas
            .intersection(Gitlab::Database.all_database_connections["ci"].gitlab_schemas)

          ci_only_schemas.each do |ci_schema|
            Gitlab::Database::BumpSequences.new(ci_schema, increase_by).execute
          end
        end
      end
    end
  end
end
