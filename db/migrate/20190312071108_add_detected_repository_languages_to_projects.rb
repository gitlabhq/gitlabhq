# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddDetectedRepositoryLanguagesToProjects < ActiveRecord::Migration[5.0]
  DOWNTIME = false

  def change
    add_column :projects, :detected_repository_languages, :boolean # rubocop:disable Migration/AddColumnsToWideTables
  end
end
