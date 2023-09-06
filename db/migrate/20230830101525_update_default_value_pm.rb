# frozen_string_literal: true

class UpdateDefaultValuePm < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  FULLY_ENABLED_SYNC = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].freeze

  def change
    change_column_default :application_settings, :package_metadata_purl_types, from: [], to: FULLY_ENABLED_SYNC
  end
end
