# frozen_string_literal: true

class AddIndexServicesOnTemplate < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # This migration is a corrective action to add the missing
  # index_services_on_template index on staging.
  def up
    add_concurrent_index(:services, :template) unless index_exists?(:services, :template)
  end

  def down
    # No reverse action as this is a corrective migration.
  end
end
