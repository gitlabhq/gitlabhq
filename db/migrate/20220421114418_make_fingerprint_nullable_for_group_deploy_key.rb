# frozen_string_literal: true

class MakeFingerprintNullableForGroupDeployKey < Gitlab::Database::Migration[2.0]
  def up
    change_column_null :group_deploy_keys, :fingerprint, true
  end

  def down
    # There may now be nulls in the table, so we cannot re-add the constraint here.
  end
end
