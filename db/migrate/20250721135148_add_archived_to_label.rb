# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddArchivedToLabel < Gitlab::Database::Migration[2.3]
  milestone '18.3'

  def change
    add_column :labels, :archived, :boolean, default: false, null: false
  end
end
