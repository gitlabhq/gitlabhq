class AddCiToProject < ActiveRecord::Migration
  def change
    add_column :projects, :ci_id, :integer
    add_column :projects, :builds_enabled, :boolean, default: true, null: false
    add_column :projects, :shared_runners_enabled, :boolean, default: true, null: false
    add_column :projects, :runners_token, :string
    add_column :projects, :build_coverage_regex, :string
    add_column :projects, :build_allow_git_fetch, :boolean, default: true, null: false
    add_column :projects, :build_timeout, :integer, default: 3600, null: false
  end
end
