# frozen_string_literal: true

class ValidateIssueMetricsIssueIdForeignKey < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  milestone '18.10'

  TABLE_NAME = 'issue_metrics'
  COLUMN = %w[issue_id].freeze
  FK_NAME = 'fk_rails_4bb543d85d_tmp'

  def up
    return if skip_bigint_migration?(TABLE_NAME, COLUMN)

    validate_foreign_key :issue_metrics, :issue_id, name: FK_NAME
  end

  def down
    # NO OP
  end
end
