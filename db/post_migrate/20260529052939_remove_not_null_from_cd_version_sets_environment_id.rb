# frozen_string_literal: true

class RemoveNotNullFromCdVersionSetsEnvironmentId < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '19.1'

  def up
    change_column_null :cd_version_sets, :environment_id, true
  end

  def down
    change_column_null :cd_version_sets, :environment_id, false
  end
end
