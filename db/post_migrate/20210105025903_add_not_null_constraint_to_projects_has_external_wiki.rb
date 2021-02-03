# frozen_string_literal: true

class AddNotNullConstraintToProjectsHasExternalWiki < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_not_null_constraint :projects, :has_external_wiki, validate: false
  end

  def down
    remove_not_null_constraint :projects, :has_external_wiki
  end
end
