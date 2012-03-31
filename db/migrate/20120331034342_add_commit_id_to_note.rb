class AddCommitIdToNote < ActiveRecord::Migration
  def up
    add_column :notes, :commit_id, :string
  end

  def down
  end
end
