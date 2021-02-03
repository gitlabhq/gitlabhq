# frozen_string_literal: true

class RemoveHasExternalWikiConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # This reverts the following migration: add_not_null_constraint :projects, :has_external_wiki, validate: false
    remove_not_null_constraint :projects, :has_external_wiki
  end

  def down
    # no-op
  end
end
