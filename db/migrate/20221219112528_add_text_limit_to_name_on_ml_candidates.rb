# frozen_string_literal: true

class AddTextLimitToNameOnMlCandidates < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :ml_candidates, :name, 255
  end

  def down
    remove_text_limit :ml_candidates, :name
  end
end
