# frozen_string_literal: true

class AddTagNameToCiRunnerTaggings < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in
  # 20250917172856_add_text_limit_to_ci_runner_taggings_tag_name
  def change
    add_column(:ci_runner_taggings, :tag_name, :text, null: true)
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
