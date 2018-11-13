class ResolveOutdatedDiffDiscussions < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column(:projects, :resolve_outdated_diff_discussions, :boolean)
  end
end
