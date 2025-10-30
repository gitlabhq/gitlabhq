# frozen_string_literal: true

module ClickHouse
  class SchemaValidator
    SCHEMA_FILENAME = "db/click_house/main.sql" # Only supporting main schema, for now

    def self.validate!
      puts "Running ClickHouse migrations..."
      migration_success = system("bundle exec rake gitlab:clickhouse:migrate:main gitlab:clickhouse:schema:dump:main")

      unless migration_success
        puts "ERROR: ClickHouse migration failed"
        return false
      end

      puts "Checking for schema changes..."
      diff_output = execute_git_diff

      unless diff_output
        puts "ERROR: Git diff command failed"
        return false
      end

      # rubocop:disable Rails/NegateInclude -- called without Rails context, no ActiveSupport methods available.
      schema_is_clean = !diff_output.include?(SCHEMA_FILENAME)
      # rubocop:enable Rails/NegateInclude

      if schema_is_clean
        puts "Schema is up to date - no changes detected"
      else
        puts "Schema has uncommitted changes after migration"
        puts "Changes detected in: #{SCHEMA_FILENAME}"
        puts "Diff output:"
        puts `git diff -- #{SCHEMA_FILENAME}`
      end

      schema_is_clean
    end

    def self.execute_git_diff
      output = `git diff --name-only -- #{SCHEMA_FILENAME}`
      output if git_command_successful?
    end

    def self.git_command_successful?
      $?.success?
    end
  end
end
