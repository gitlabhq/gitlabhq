# frozen_string_literal: true

class AddTextLimitToPackagesStatusMessage < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :packages_packages, :status_message, 255, validate: false
  end

  def down
    remove_text_limit :packages_packages, :status_message
  end
end
