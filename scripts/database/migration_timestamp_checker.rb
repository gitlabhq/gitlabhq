# frozen_string_literal: true

require 'time'

# Checks for migration timestamps
class MigrationTimestampChecker
  MIGRATION_DIRS = %w[db/migrate db/post_migrate].freeze
  VERSION_DIGITS = 14
  MIGRATION_TIMESTAMP_REGEX = /\A(?<version>\d{#{VERSION_DIGITS}})_/
  ERROR_CODE = 1
  Result = Struct.new(:error_code, :error_message)

  def initialize
    @invalid_migrations = Hash.new { |h, k| h[k] = [] }
  end

  def check
    check_for_timestamps

    return if invalid_migrations.empty?

    Result.new(ERROR_CODE, "\e[31mError: Invalid Timestamp was found in migrations \n\n#{message}\e[0m")
  end

  private

  attr_reader :invalid_migrations

  def maximum_timestamp
    Time.now.utc.strftime('%Y%m%d%H%M%S').to_i
  end

  def check_for_timestamps
    MIGRATION_DIRS.each do |migration_dir|
      Dir[File.join(migration_dir, '*.rb')].each do |filename|
        file_basename = File.basename(filename)
        version_match = MIGRATION_TIMESTAMP_REGEX.match(file_basename)

        raise "#{filename} has an invalid migration version" if version_match.nil?

        migration_timestamp = version_match['version'].to_i
        invalid_migrations[filename] = "has a future timestamp" if future_timestamp?(migration_timestamp)
      end
    end
  end

  def future_timestamp?(migration_timestamp)
    migration_timestamp > maximum_timestamp
  end

  def message
    invalid_migrations.map { |filename, error| "#{filename}: #{error}\n" }.join('')
  end
end
