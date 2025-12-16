# frozen_string_literal: true

require 'yaml'
require 'diffy'
require 'rainbow'

# Checks the alphabetical ordering of table names
# in config/gitlab_loose_foreign_keys.yml
class LooseForeignKeysOrderingChecker
  LOOSE_FOREIGN_KEYS_PATH = 'config/gitlab_loose_foreign_keys.yml'
  ERROR_CODE = 1

  Result = Struct.new(:error_code, :error_message)

  def check
    unless File.exist?(LOOSE_FOREIGN_KEYS_PATH)
      return Result.new(ERROR_CODE, Rainbow("Error: #{LOOSE_FOREIGN_KEYS_PATH} not found").red)
    end

    yaml_content = File.read(LOOSE_FOREIGN_KEYS_PATH)
    parsed = YAML.safe_load(yaml_content)

    return if parsed.nil? || parsed.empty?

    table_names = parsed.keys
    sorted_table_names = table_names.sort

    return if table_names == sorted_table_names

    format_error_result(table_names, sorted_table_names)
  end

  private

  def format_error_result(table_names, sorted_table_names)
    message = Rainbow("Error: Table names in #{LOOSE_FOREIGN_KEYS_PATH} are not in alphabetical order\n\n").red
    message += "The following order is expected:\n\n"

    diff = Diffy::Diff.new(table_names.join("\n"), sorted_table_names.join("\n")).to_s(:color)
    diff = diff.split("\n").reject { |l| l.include?('No newline at end of file') }.join("\n")
    message += "#{diff}\n\n"

    message += Rainbow("Please reorder the tables alphabetically.\n").red

    Result.new(ERROR_CODE, message)
  end
end
