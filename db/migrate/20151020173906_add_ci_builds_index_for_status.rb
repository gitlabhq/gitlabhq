# rubocop:disable all
class AddCiBuildsIndexForStatus < ActiveRecord::Migration[4.2]
  def change
    add_index :ci_builds, [:commit_id, :status, :type]
  end
end
