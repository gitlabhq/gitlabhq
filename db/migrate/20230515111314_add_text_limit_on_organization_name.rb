# frozen_string_literal: true

class AddTextLimitOnOrganizationName < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :organizations, :name, 255
  end

  def down
    remove_text_limit :organizations, :name
  end
end
