# frozen_string_literal: true

class AddTextLimitToGloballyAllowedIpsOnApplicationSettings < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :globally_allowed_ips, 255
  end

  def down
    remove_text_limit :application_settings, :globally_allowed_ips
  end
end
