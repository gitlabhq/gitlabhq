# frozen_string_literal: true

class AddBigintForeignKeysOnIssueMetrics < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::ConvertToBigint

  disable_ddl_transaction!
  milestone '18.9'

  FK_NAME = 'fk_rails_4bb543d85d_tmp'

  def up
    unless column_exists?(:issue_metrics, :issue_id_convert_to_bigint)
      say "Corresponding bigint column issue_id_convert_to_bigint does not exist on issue_metrics"

      return
    end

    add_concurrent_foreign_key(
      :issue_metrics,
      :issues,
      column: :issue_id_convert_to_bigint,
      target_column: :id,
      name: FK_NAME,
      on_delete: :cascade,
      validate: false,
      reverse_lock_order: true
    )

    prepare_async_foreign_key_validation(
      :issue_metrics,
      :issue_id_convert_to_bigint,
      name: FK_NAME
    )
  end

  def down
    remove_foreign_key_if_exists(
      :issue_metrics,
      :issues,
      name: FK_NAME,
      reverse_lock_order: true
    )

    unprepare_async_foreign_key_validation(
      :issue_metrics,
      name: FK_NAME
    )
  end
end
