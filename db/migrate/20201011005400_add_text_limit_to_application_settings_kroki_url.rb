# frozen_string_literal: true

class AddTextLimitToApplicationSettingsKrokiUrl < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :kroki_url, 1024
  end

  def down
    # Down is required as `add_text_limit` is not reversible
    #
    remove_text_limit :application_settings, :kroki_url
  end
end
