# frozen_string_literal: true

class ExtendPushRulesRegexLimits < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  REGEX_COLUMNS = %i[
    force_push_regex
    delete_branch_regex
    commit_message_regex
    author_email_regex
    file_name_regex
    branch_name_regex
  ].freeze

  LONG_REGEX_COLUMNS = %i[commit_message_negative_regex]

  def up
    REGEX_COLUMNS.each do |column_name|
      add_check_constraint :push_rules, "char_length(#{column_name}) <= 511", "#{column_name}_size_constraint",
        validate: false
    end

    LONG_REGEX_COLUMNS.each do |column_name|
      next unless column_exists?(:push_rules, column_name)

      add_check_constraint :push_rules, "char_length(#{column_name}) <= 2047", "#{column_name}_size_constraint",
        validate: false
    end
  end

  def down
    REGEX_COLUMNS.each do |column_name|
      remove_check_constraint :push_rules, "#{column_name}_size_constraint"
    end

    LONG_REGEX_COLUMNS.each do |column_name|
      next unless column_exists?(:push_rules, column_name)

      remove_check_constraint :push_rules, "#{column_name}_size_constraint"
    end
  end
end
