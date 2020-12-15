# frozen_string_literal: true

class AddTextLimitToApplicationSettingPersonalAccessTokenPrefix < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :personal_access_token_prefix, 20
  end

  def down
    remove_text_limit :application_settings, :personal_access_token_prefix
  end
end
