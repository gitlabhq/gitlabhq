# rubocop:disable all
class MigrateRebaseFeature < ActiveRecord::Migration
  def up
    execute %q{UPDATE projects SET merge_requests_ff_only_enabled = TRUE WHERE merge_requests_rebase_enabled IS TRUE}

    remove_column :projects, :merge_requests_rebase_default
  end

  def down
    add_column :projects, :merge_requests_rebase_default, :boolean, default: true
  end
end
