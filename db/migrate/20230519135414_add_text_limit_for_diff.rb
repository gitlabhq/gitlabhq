# frozen_string_literal: true

class AddTextLimitForDiff < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :schema_inconsistencies, :diff, 6144
  end

  def down
    remove_text_limit :schema_inconsistencies, :diff
  end
end
