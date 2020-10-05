# frozen_string_literal: true

class ValidateDesignsFilenameTextLimit < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_text_limit :design_management_designs, :filename
  end

  def down
    # no-op
  end
end
