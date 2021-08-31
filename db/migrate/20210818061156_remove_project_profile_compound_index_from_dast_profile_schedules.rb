# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveProjectProfileCompoundIndexFromDastProfileSchedules < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  TABLE = :dast_profile_schedules
  INDEX_NAME = 'index_dast_profile_schedules_on_project_id_and_dast_profile_id'
  # We disable these cops here because changing this index is safe. The table does not
  # have any data in it as it's behind a feature flag.
  # rubocop: disable Migration/AddIndex
  # rubocop: disable Migration/RemoveIndex
  def up
    execute('DELETE FROM dast_profile_schedules')

    if index_exists_by_name?(TABLE, INDEX_NAME)
      remove_index TABLE, %i[project_id dast_profile_id], name: INDEX_NAME
    end
  end

  def down
    execute('DELETE FROM dast_profile_schedules')

    unless index_exists_by_name?(TABLE, INDEX_NAME)
      add_index TABLE, %i[project_id dast_profile_id], unique: true, name: INDEX_NAME
    end
  end
end
