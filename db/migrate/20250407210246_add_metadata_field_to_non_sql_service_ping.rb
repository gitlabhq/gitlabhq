# frozen_string_literal: true

class AddMetadataFieldToNonSqlServicePing < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  def change
    add_column(:non_sql_service_pings, :metadata, :jsonb)
  end
end
