# frozen_string_literal: true

class AddTextLimitToDastSiteValidationState < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :dast_site_validations, :state, 255
  end

  def down
    remove_text_limit :dast_site_validations, :state
  end
end
