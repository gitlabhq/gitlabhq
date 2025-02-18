# frozen_string_literal: true

require 'open3'
require 'yaml'

class MigrationSchemaValidator
  FILENAME = 'db/structure.sql'

  MIGRATION_DIRS = %w[db/migrate db/post_migrate].freeze

  SCHEMA_VERSION_DIR = 'db/schema_migrations'

  MODELS_DIR = 'app/models'
  EE_MODELS_DIR = 'ee/app/models'

  DB_DOCS_DIR = 'db/docs'
  DOC_URL = "https://docs.gitlab.com/ee/development/database/avoiding_downtime_in_migrations.html"

  VERSION_DIGITS = 14

  SKIP_VALIDATION_LABEL = 'pipeline:skip-check-migrations'

  MIGRATION_METHODS = %w[
    cleanup_concurrent_column_rename
    cleanup_conversion_of_integer_to_bigint
    rename_column
    rename_column_concurrently
    remove_column
  ].freeze
  MIGRATION_METHODS_REGEX = /(#{MIGRATION_METHODS.join('|')})[(\s]/
  TABLE_AND_COLUMN_NAME_REGEX = /(?:#{MIGRATION_METHODS.join('|')})\s+:(\w+),\s+:(\w+)/
  UP_OR_CHANGE_METHOD_REGEX = /def (?:up|change)(.*?)end/m

  PERMITTED_YAML_CLASSES = [String, Array, Hash].freeze

  def initialize
    @models_missing_ignore = Hash.new { |h, k| h[k] = [] }
  end

  def validate!
    if committed_migrations.empty?
      puts "\e[32m No migrations found, skipping schema validation\e[0m"
      return
    end

    # validate_ignore_columns! should never be skipped, the ignore_column directive must always be present
    validate_ignore_columns!

    if skip_validation?
      puts "\e[32m Label #{SKIP_VALIDATION_LABEL} is present, skipping schema validation\e[0m"
      return
    end

    validate_schema_on_rollback!
    validate_schema_on_migrate!
    validate_schema_version_files!
  end

  private

  def skip_validation?
    ENV.fetch('CI_MERGE_REQUEST_LABELS', '').split(',').include?(SKIP_VALIDATION_LABEL)
  end

  def validate_ignore_columns!
    base_message = <<~MSG.freeze
        Column operations, like dropping, renaming or primary key conversion, require columns to be ignored in
        the model. This step is necessary because Rails caches the columns and re-uses it in various places across the
        application. Refer to these pages for more information:

        #{DOC_URL}#dropping-columns
        #{DOC_URL}#renaming-columns
        #{DOC_URL}#migrating-integer-primary-keys-to-bigint

        Please ensure that columns are properly ignored in the models
    MSG

    committed_migrations.each do |file_name|
      check_file(file_name)
    end

    return if @models_missing_ignore.empty?

    models_missing_text = @models_missing_ignore.map { |key, values| "#{key}: #{values.join(', ')}" }.join("\n")
    die "#{base_message}\n#{models_missing_text}"
  end

  def extract_up_or_change_method(file_content)
    method_content = file_content.match(UP_OR_CHANGE_METHOD_REGEX)
    method_content ? method_content[1].strip : nil
  end

  def check_file(file_path)
    return unless File.exist?(file_path)

    file_content = File.read(file_path)
    method_content = extract_up_or_change_method(file_content)
    return unless method_content&.match?(MIGRATION_METHODS_REGEX)

    table_column_pairs = method_content.scan(TABLE_AND_COLUMN_NAME_REGEX)
    table_column_pairs.each do |table, column|
      model_name = model(table)
      next unless model_name

      model_file_path = model_path(model_name)
      next unless File.exist?(model_file_path)

      model_content = File.read(model_file_path)
      next if model_content.match?(/\s(ignore_column|ignore_columns)\s(:|%i\[)\s*#{column}/)

      @models_missing_ignore[model_name.to_s] << column
    end
  end

  def model(table_name)
    db_docs_file = File.join(DB_DOCS_DIR, "#{table_name}.yml")
    return unless File.exist?(db_docs_file)

    data = YAML.safe_load(File.read(db_docs_file), permitted_classes: PERMITTED_YAML_CLASSES)
    data['classes'].first
  rescue Psych::DisallowedClass => e
    puts "Error: Unexpected object type in YAML file for table '#{table_name}': #{e.message}"
    nil
  end

  def model_path(model)
    nested_model = underscore(model)
    file_path = File.join(MODELS_DIR, "#{nested_model}.rb")

    if File.exist?(file_path)
      file_path
    else
      File.join(EE_MODELS_DIR, "#{nested_model}.rb")
    end
  end

  def underscore(str)
    str.gsub(/::/, '/')
      .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
      .gsub(/([a-z\d])([A-Z])/, '\1_\2')
      .tr("-", "_")
      .downcase
  end

  def validate_schema_on_rollback!
    committed_migrations.reverse_each do |filename|
      version = find_migration_version(filename)

      run("scripts/db_tasks db:migrate:down VERSION=#{version}")
      run("scripts/db_tasks db:schema:dump")
    end

    git_command = "git diff #{diff_target} -- #{FILENAME}"
    base_message = "rollback of added migrations does not revert #{FILENAME} to previous state, " \
      "please investigate. Apply the '#{SKIP_VALIDATION_LABEL}' label to skip this check if needed." \
      "If you are unsure why this job is failing for your MR, then please refer to this page: " \
      "https://docs.gitlab.com/ee/development/database/dbcheck-migrations-job.html#false-positives"

    validate_clean_output!(git_command, base_message)
  end

  def validate_schema_on_migrate!
    run("scripts/db_tasks db:migrate")
    run("scripts/db_tasks db:schema:dump")

    git_command = "git diff -- #{FILENAME}"
    base_message = "the committed #{FILENAME} does not match the one generated by running added migrations"

    validate_clean_output!(git_command, base_message)
  end

  def validate_schema_version_files!
    git_command = "git add -A -n #{SCHEMA_VERSION_DIR}"
    base_message = "the committed files in #{SCHEMA_VERSION_DIR} do not match those expected by the added migrations"

    validate_clean_output!(git_command, base_message)
  end

  def committed_migrations
    @committed_migrations ||= begin
      git_command = "git diff --name-only --diff-filter=A #{diff_target} -- #{MIGRATION_DIRS.join(' ')}"

      run(git_command).split("\n")
    end
  end

  def diff_target
    @diff_target ||= pipeline_for_merged_results? ? target_branch : merge_base
  end

  def merge_base
    run("git merge-base #{target_branch} #{source_ref}")
  end

  def target_branch
    ENV['CI_MERGE_REQUEST_TARGET_BRANCH_NAME'] || ENV['TARGET'] || ENV['CI_DEFAULT_BRANCH'] || 'master'
  end

  def source_ref
    ENV['CI_COMMIT_SHA'] || 'HEAD'
  end

  def pipeline_for_merged_results?
    ENV.key?('CI_MERGE_REQUEST_SOURCE_BRANCH_SHA')
  end

  def find_migration_version(filename)
    file_basename = File.basename(filename)
    version_match = /\A(?<version>\d{#{VERSION_DIGITS}})_/o.match(file_basename)

    die "#{filename} has an invalid migration version" if version_match.nil?

    version_match[:version]
  end

  def validate_clean_output!(command, base_message)
    command_output = run(command)

    return if command_output.empty?

    die "#{base_message}:\n#{command_output}"
  end

  def die(message, error_code: 1)
    puts "\e[31mError: #{message}\e[0m"
    exit error_code
  end

  def run(cmd)
    puts "\e[32m$ #{cmd}\e[37m"
    stdout_str, stderr_str, status = Open3.capture3(cmd)
    puts "#{stdout_str}#{stderr_str}\e[0m"

    die "command failed: #{stderr_str}" unless status.success?

    stdout_str.chomp
  end
end
