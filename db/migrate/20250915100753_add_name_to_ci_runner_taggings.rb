# frozen_string_literal: true

class AddNameToCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in 20250915120257_add_text_limit_to_ci_runner_taggings_name
  def change
    add_column(:ci_runner_taggings, :name, :text, null: true)
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
