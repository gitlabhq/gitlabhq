# frozen_string_literal: true

class AddTextLimitToArkoseVerifyUrlApplicationSettings < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :arkose_labs_verify_api_url, 255
  end

  def down
    remove_text_limit :application_settings, :arkose_labs_verify_api_url
  end
end
