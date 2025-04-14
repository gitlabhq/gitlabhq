# frozen_string_literal: true

class DropNotNullFromCloudConnectorAccessData < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '18.0'

  def up
    change_column_null :cloud_connector_access, :data, true
  end

  def down
    # no-op
  end
end
