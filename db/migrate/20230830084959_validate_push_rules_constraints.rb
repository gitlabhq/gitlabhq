# frozen_string_literal: true

class ValidatePushRulesConstraints < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  REGEX_COLUMNS = %i[
    force_push_regex
    delete_branch_regex
    commit_message_regex
    commit_message_negative_regex
    author_email_regex
    file_name_regex
    branch_name_regex
  ].freeze

  def up
    REGEX_COLUMNS.each do |column_name|
      next unless column_exists?(:push_rules, column_name)

      validate_check_constraint :push_rules, "#{column_name}_size_constraint"
    end
  end

  def down
    # No op
  end
end
