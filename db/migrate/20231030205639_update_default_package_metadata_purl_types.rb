# frozen_string_literal: true

class UpdateDefaultPackageMetadataPurlTypes < Gitlab::Database::Migration[2.2]
  milestone '16.6'

  disable_ddl_transaction!

  PARTIALLY_ENABLED_SYNC = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12].freeze
  FULLY_ENABLED_SYNC     = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13].freeze

  def change
    change_column_default :application_settings, :package_metadata_purl_types,
      from: PARTIALLY_ENABLED_SYNC, to: FULLY_ENABLED_SYNC
  end
end
