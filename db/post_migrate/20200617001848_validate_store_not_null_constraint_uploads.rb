# frozen_string_literal: true

class ValidateStoreNotNullConstraintUploads < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    validate_check_constraint(:uploads, :check_5e9547379c)
  end

  def down
    # no-op
  end
end
