# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddTrialEndsOnToNamespaces < ActiveRecord::Migration
  DOWNTIME = false

  def change
    add_column :namespaces, :trial_ends_on, :datetime_with_timezone
  end
end
