# frozen_string_literal: true

# Checks for presence of migration checksum files when adding new migrations
class MigrationChecksumChecker
  MIGRATION_DIRS = %w[db/migrate db/post_migrate].freeze
  CHECKSUM_DIR = 'db/schema_migrations'
  TIMESTAMP_REGEX = /\A(\d+)_/
  CHECKSUM_LENGTH = 64
  ERROR_CODE = 1

  Result = Struct.new(:error_code, :error_message)

  def check
    missing_or_invalid_files = find_checksum_issues

    return if missing_or_invalid_files.empty?

    format_error_result(missing_or_invalid_files)
  end

  private

  def find_checksum_issues
    issues = {}

    MIGRATION_DIRS.each do |migration_dir|
      next unless Dir.exist?(migration_dir)

      Dir[File.join(migration_dir, '*.rb')].each do |migration_file|
        timestamp = extract_timestamp(migration_file)
        next unless timestamp

        checksum_file = File.join(CHECKSUM_DIR, timestamp)

        if !File.exist?(checksum_file)
          issues[migration_file] = "Missing checksum file"
        elsif File.zero?(checksum_file)
          issues[migration_file] = "Empty checksum file"
        else
          checksum_content = File.read(checksum_file).chomp
          issues[migration_file] = "Invalid checksum length" if checksum_content.length != CHECKSUM_LENGTH
        end
      end
    end

    issues
  end

  def extract_timestamp(filename)
    file_basename = File.basename(filename)
    match = TIMESTAMP_REGEX.match(file_basename)
    match ? match[1] : nil
  end

  def format_error_result(issues)
    message = issues.map do |file, issue_type|
      "#{issue_type} for migration: #{file}\n"
    end.join('')

    Result.new(ERROR_CODE, "\e[31mError: Issues found with migration checksum files\n\n#{message}\e[0m")
  end
end
