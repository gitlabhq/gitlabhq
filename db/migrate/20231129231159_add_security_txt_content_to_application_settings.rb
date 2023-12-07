# frozen_string_literal: true

class AddSecurityTxtContentToApplicationSettings < Gitlab::Database::Migration[2.2]
  milestone '16.7'
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :application_settings, :security_txt_content, :text, if_not_exists: true
    end

    add_text_limit :application_settings, :security_txt_content, 2048
  end

  def down
    with_lock_retries do
      remove_column :application_settings, :security_txt_content, if_exists: true
    end
  end
end
