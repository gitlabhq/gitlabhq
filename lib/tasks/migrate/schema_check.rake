desc 'Configures the database by running migrate, or by loading the schema and seeding if needed'
task schema_version_check: :environment do
  schema_version = ActiveRecord::Migrator.current_version

  # Ensure migrations are being run from a supported schema version
  # A schema verison of 0 is a fresh db, and should be safe to run migrations
  # But a database with existing migrations less than our min version is not
  if schema_version > 0 && schema_version < Gitlab::Database::MIN_SCHEMA_VERSION
    raise "Your current database version is too old to be migrated. " \
          "You should upgrade to GitLab #{Gitlab::Database::MIN_SCHEMA_GITLAB_VERSION} before moving to this version. " \
          "Please see https://docs.gitlab.com/ee/policy/maintenance.html#upgrade-recommendations"
  end
end

# Ensure the check is a pre-requisite when running db:migrate
Rake::Task["db:migrate"].enhance [:schema_version_check]
