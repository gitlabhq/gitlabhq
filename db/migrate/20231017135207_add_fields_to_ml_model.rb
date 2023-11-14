# frozen_string_literal: true

class AddFieldsToMlModel < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20231018152419_add_text_limit_to_ml_models.rb
    add_column :ml_models, :description, :text
    # rubocop:enable Migration/AddLimitToTextColumns

    add_column :ml_models, :user_id, :integer, null: true
    add_concurrent_foreign_key :ml_models, :users, column: :user_id, on_delete: :nullify

    add_concurrent_index :ml_models, :user_id
  end

  def down
    remove_column :ml_models, :description
    remove_column :ml_models, :user_id
    remove_foreign_key_if_exists :ml_models, column: :user_id
  end
end
