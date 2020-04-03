# frozen_string_literal: true

class AddConfidentialAttributeToEpics < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:epics, :confidential, :boolean, default: false)
  end

  def down
    remove_column(:epics, :confidential)
  end
end
