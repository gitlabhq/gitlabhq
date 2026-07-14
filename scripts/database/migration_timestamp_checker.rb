# frozen_string_literal: true

require 'time'

# Checks for migration timestamps
class MigrationTimestampChecker
  MIGRATION_DIRS = %w[db/migrate db/post_migrate].freeze
  VERSION_DIGITS = 14
  MIGRATION_TIMESTAMP_REGEX = /\A(?<version>\d{#{VERSION_DIGITS}})_/
  # Migrations should be merged within three weeks of their timestamp.
  # See https://docs.gitlab.com/development/migration_style_guide/#migration-timestamp-age
  MAX_TIMESTAMP_AGE_IN_SECONDS = 3 * 7 * 24 * 60 * 60
  ERROR_CODE = 1
  Result = Struct.new(:error_code, :error_message)

  def initialize
    @invalid_migrations = Hash.new { |h, k| h[k] = [] }
  end

  def check
    check_for_timestamps

    return if invalid_migrations.empty?

    Result.new(ERROR_CODE, "\e[31mError: Invalid Timestamp was found in migrations \n\n#{message}\n#{hint}\e[0m")
  end

  private

  attr_reader :invalid_migrations

  def maximum_timestamp
    Time.now.utc.strftime('%Y%m%d%H%M%S').to_i
  end

  def minimum_timestamp
    (Time.now.utc - MAX_TIMESTAMP_AGE_IN_SECONDS).strftime('%Y%m%d%H%M%S').to_i
  end

  def check_for_timestamps
    MIGRATION_DIRS.each do |migration_dir|
      Dir[File.join(migration_dir, '*.rb')].each do |filename|
        file_basename = File.basename(filename)
        version_match = MIGRATION_TIMESTAMP_REGEX.match(file_basename)

        raise "#{filename} has an invalid migration version" if version_match.nil?

        migration_timestamp = version_match['version'].to_i

        if future_timestamp?(migration_timestamp)
          invalid_migrations[filename] = "has a future timestamp"
        elsif new_migration?(filename) && old_timestamp?(migration_timestamp)
          invalid_migrations[filename] = "has a timestamp older than three weeks, " \
            "see https://docs.gitlab.com/development/migration_style_guide/#migration-timestamp-age"
        end
      end
    end
  end

  def future_timestamp?(migration_timestamp)
    migration_timestamp > maximum_timestamp
  end

  def old_timestamp?(migration_timestamp)
    migration_timestamp < minimum_timestamp
  end

  # The three-week age limit only applies to migrations added in the current
  # branch. Pre-existing migrations are expected to have older timestamps.
  def new_migration?(filename)
    new_migrations.include?(filename)
  end

  def new_migrations
    @new_migrations ||= begin
      git_command = "git diff --name-only --diff-filter=A #{diff_target}...HEAD -- #{MIGRATION_DIRS.join(' ')}"

      `#{git_command}`.split("\n").map(&:strip)
    rescue StandardError
      []
    end
  end

  def diff_target
    ENV['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'] || ENV['TARGET'] || ENV['CI_DEFAULT_BRANCH'] || 'master'
  end

  def message
    invalid_migrations.map { |filename, error| "#{filename}: #{error}\n" }.join('')
  end

  def hint
    "To fix this, refresh the migration timestamps by running:\n\n  scripts/refresh-migrations-timestamps\n"
  end
end
