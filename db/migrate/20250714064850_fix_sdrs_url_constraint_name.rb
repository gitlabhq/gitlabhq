# frozen_string_literal: true

class FixSdrsUrlConstraintName < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  disable_ddl_transaction!

  OLD_CONSTRAINT_NAME = 'check_9a42a7cfdd'

  def up
    add_text_limit :application_settings, :sdrs_url, 255

    remove_check_constraint :application_settings, OLD_CONSTRAINT_NAME
  end

  def down
    remove_text_limit :application_settings, :sdrs_url

    add_check_constraint :application_settings,
      "char_length(sdrs_url) <= 255",
      OLD_CONSTRAINT_NAME
  end
end
