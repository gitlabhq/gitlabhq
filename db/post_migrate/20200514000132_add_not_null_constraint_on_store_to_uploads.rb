# frozen_string_literal: true

class AddNotNullConstraintOnStoreToUploads < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_not_null_constraint(:uploads, :store, validate: false)
  end

  def down
    remove_not_null_constraint(:uploads, :store)
  end
end
