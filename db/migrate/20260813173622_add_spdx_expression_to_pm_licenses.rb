# frozen_string_literal: true

class AddSpdxExpressionToPmLicenses < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.4'

  INDEX_NAME = 'i_pm_licenses_on_spdx_expression'

  def up
    change_column_null :pm_licenses, :spdx_identifier, true

    with_lock_retries do
      add_column :pm_licenses, :spdx_expression, :text, if_not_exists: true
    end

    add_text_limit :pm_licenses, :spdx_expression, 1024
    add_concurrent_index :pm_licenses, :spdx_expression, unique: true, name: INDEX_NAME
    add_multi_column_not_null_constraint :pm_licenses, :spdx_identifier, :spdx_expression
  end

  def down
    remove_multi_column_not_null_constraint :pm_licenses, :spdx_identifier, :spdx_expression
    remove_concurrent_index_by_name :pm_licenses, INDEX_NAME
    remove_text_limit :pm_licenses, :spdx_expression

    with_lock_retries do
      remove_column :pm_licenses, :spdx_expression, if_exists: true
    end

    change_column_null :pm_licenses, :spdx_identifier, false
  end
end
