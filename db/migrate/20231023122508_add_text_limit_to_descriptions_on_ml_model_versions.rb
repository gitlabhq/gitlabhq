# frozen_string_literal: true

class AddTextLimitToDescriptionsOnMlModelVersions < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :ml_model_versions, :description, 500
  end

  def down
    remove_text_limit :ml_model_versions, :description
  end
end
