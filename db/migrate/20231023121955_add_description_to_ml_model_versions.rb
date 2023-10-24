# frozen_string_literal: true

class AddDescriptionToMlModelVersions < Gitlab::Database::Migration[2.1]
  def change
    # rubocop:disable Migration/AddLimitToTextColumns -- limit being added on 20231023122508
    add_column :ml_model_versions, :description, :text
    # rubocop:enable Migration/AddLimitToTextColumns
  end
end
