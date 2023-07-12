# frozen_string_literal: true

class AddColumnModelIdToMlExperiments < Gitlab::Database::Migration[2.1]
  def change
    # rubocop:disable Migration/AddReference
    add_reference :ml_experiments,
      :model,
      index: true,
      null: true,
      unique: true,
      foreign_key: { on_delete: :cascade, to_table: :ml_models }
    # rubocop:enable Migration/AddReference
  end
end
