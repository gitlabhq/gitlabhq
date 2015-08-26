class AddCoverageParser < ActiveRecord::Migration
  def change
    add_column :projects, :coverage_regex, :string
  end
end
