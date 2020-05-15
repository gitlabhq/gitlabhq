# frozen_string_literal: true

class AddNpmPackageRequestsForwardingToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :npm_package_requests_forwarding, # rubocop:disable Migration/AddColumnWithDefault
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :npm_package_requests_forwarding)
  end
end
