# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddIndexProjectIdOnDastProfileSchedule < ActiveRecord::Migration[6.1]
  # We disable these cops here because changing this index is safe. The table does not
  # have any data in it as it's behind a feature flag.
  # rubocop: disable Migration/AddIndex
  def change
    add_index :dast_profile_schedules, :project_id
  end
end
