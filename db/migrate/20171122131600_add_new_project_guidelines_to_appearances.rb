class AddNewProjectGuidelinesToAppearances < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    # Clears the current Appearance cache otherwise it breaks since
    # new_project_guidelines_html would be missing. See
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/41041
    # We're not using Appearance#flush_redis_cache on purpose here.
    Rails.cache.delete('current_appearance')

    change_table :appearances do |t|
      t.text :new_project_guidelines
      t.text :new_project_guidelines_html
    end
  end
end
