# frozen_string_literal: true

class AddConfidentialToDoorkeeperApplication < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default( # rubocop:disable Migration/AddColumnWithDefault
      :oauth_applications,
      :confidential,
      :boolean,
      default: false, # assume all existing applications are non-confidential
      allow_null: false
    )

    # set the default to true so that all future applications are confidential by default
    change_column_default(:oauth_applications, :confidential, true)
  end

  def down
    remove_column :oauth_applications, :confidential
  end
end
