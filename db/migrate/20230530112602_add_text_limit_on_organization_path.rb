# frozen_string_literal: true

class AddTextLimitOnOrganizationPath < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :organizations, :path, 255
  end

  def down
    remove_text_limit :organizations, :path
  end
end
