# frozen_string_literal: true

namespace :gitlab do
  namespace :background_migrations do
    desc 'Synchronously finish executing a batched background migration'
    task :finalize, [:job_class_name, :table_name, :column_name, :job_arguments] => :environment do |_, args|
      [:job_class_name, :table_name, :column_name, :job_arguments].each do |argument|
        unless args[argument]
          puts "Must specify #{argument} as an argument".color(:red)
          exit 1
        end
      end

      Gitlab::Database::BackgroundMigration::BatchedMigrationRunner.finalize(
        args[:job_class_name],
        args[:table_name],
        args[:column_name],
        Gitlab::Json.parse(args[:job_arguments])
      )

      puts "Done.".color(:green)
    end

    desc 'Display the status of batched background migrations'
    task status: :environment do
      statuses = Gitlab::Database::BackgroundMigration::BatchedMigration.statuses
      max_status_length = statuses.keys.map(&:length).max
      format_string = "%-#{max_status_length}s | %s\n"

      Gitlab::Database::BackgroundMigration::BatchedMigration.find_each(batch_size: 100) do |migration|
        identification_fields = [
          migration.job_class_name,
          migration.table_name,
          migration.column_name,
          migration.job_arguments.to_json
        ].join(',')

        printf(format_string, migration.status, identification_fields)
      end
    end
  end
end
