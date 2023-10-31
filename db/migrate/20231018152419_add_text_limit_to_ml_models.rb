# frozen_string_literal: true

class AddTextLimitToMlModels < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :ml_models, :description, 5000
  end

  def down
    remove_text_limit :ml_models, :description
  end
end
