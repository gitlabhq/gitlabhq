# frozen_string_literal: true

class RemoveHasExternalWikiConstraint < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # This reverts the following migration: add_not_null_constraint :projects, :has_external_wiki, validate: false
    if check_not_null_constraint_exists?(:projects, :has_external_wiki)
      remove_not_null_constraint :projects, :has_external_wiki
    end
  end

  def down
    # no-op
  end
end
