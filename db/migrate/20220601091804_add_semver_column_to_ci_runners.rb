# frozen_string_literal: true

class AddSemverColumnToCiRunners < Gitlab::Database::Migration[2.0]
  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20220601091805_add_text_limit_to_ci_runners_semver
  def up
    add_column :ci_runners, :semver, :text, null: true
  end
  # rubocop:enable Migration/AddLimitToTextColumns

  def down
    remove_column :ci_runners, :semver
  end
end
