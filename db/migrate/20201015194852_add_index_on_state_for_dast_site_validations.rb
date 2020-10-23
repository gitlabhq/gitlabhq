# frozen_string_literal: true

class AddIndexOnStateForDastSiteValidations < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  OLD_INDEX_NAME = 'index_dast_site_validations_on_url_base'
  NEW_INDEX_NAME = 'index_dast_site_validations_on_url_base_and_state'

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_concurrent_index :dast_site_validations, [:url_base, :state], name: NEW_INDEX_NAME
    remove_concurrent_index_by_name :dast_site_validations, OLD_INDEX_NAME
  end

  def down
    add_concurrent_index :dast_site_validations, :url_base, name: OLD_INDEX_NAME
    remove_concurrent_index_by_name :dast_site_validations, NEW_INDEX_NAME
  end
end
