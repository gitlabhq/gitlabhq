# frozen_string_literal: true

namespace :gitlab do
  namespace :background_migrations do
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
  end
end
