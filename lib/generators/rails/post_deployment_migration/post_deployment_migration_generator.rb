module Rails
  class PostDeploymentMigrationGenerator < Rails::Generators::NamedBase
    def create_migration_file
      timestamp = Time.now.strftime('%Y%m%d%H%I%S')

      template "migration.rb", "db/post_migrate/#{timestamp}_#{file_name}.rb"
    end

    def migration_class_name
      file_name.camelize
    end
  end
end
