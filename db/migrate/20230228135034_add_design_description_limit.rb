# frozen_string_literal: true

class AddDesignDescriptionLimit < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :design_management_designs, :description, 1_000_000
  end

  def down
    remove_text_limit :design_management_designs, :description
  end
end
