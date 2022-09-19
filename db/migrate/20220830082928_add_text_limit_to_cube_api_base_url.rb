# frozen_string_literal: true

class AddTextLimitToCubeApiBaseUrl < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :cube_api_base_url, 512
  end

  def down
    remove_text_limit :application_settings, :cube_api_base_url
  end
end
