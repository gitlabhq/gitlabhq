# frozen_string_literal: true

class RemoveArkoseLabsVerifyApiUrlColumn < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  def up
    remove_column :application_settings, :arkose_labs_verify_api_url, if_exists: true
  end

  def down
    add_column :application_settings, :arkose_labs_verify_api_url, :text, if_not_exists: true

    add_check_constraint(:application_settings, 'char_length(arkose_labs_verify_api_url) <= 255', 'check_f6563bc000')
  end
end
