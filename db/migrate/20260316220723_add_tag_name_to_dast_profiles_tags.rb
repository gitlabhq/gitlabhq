# frozen_string_literal: true

# See https://docs.gitlab.com/development/migration_style_guide/
# for more information on how to write migrations for GitLab.

class AddTagNameToDastProfilesTags < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  # rubocop:disable Migration/AddLimitToTextColumns -- limit is added in
  # a following migration
  def change
    add_column :dast_profiles_tags, :tag_name, :text, null: true
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
