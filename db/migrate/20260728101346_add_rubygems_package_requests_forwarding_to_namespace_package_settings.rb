# frozen_string_literal: true

class AddRubygemsPackageRequestsForwardingToNamespacePackageSettings < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  def change
    add_column :namespace_package_settings, :rubygems_package_requests_forwarding, :boolean
    add_column :namespace_package_settings, :lock_rubygems_package_requests_forwarding, :boolean, default: false,
      null: false
  end
end
