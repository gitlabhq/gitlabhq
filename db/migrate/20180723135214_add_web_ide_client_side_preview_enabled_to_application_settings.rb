# frozen_string_literal: true

class AddWebIdeClientSidePreviewEnabledToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column_with_default(:application_settings, :web_ide_clientside_preview_enabled,
                            :boolean,
                            default: false,
                            allow_null: false)
  end

  def down
    remove_column(:application_settings, :web_ide_clientside_preview_enabled)
  end
end
