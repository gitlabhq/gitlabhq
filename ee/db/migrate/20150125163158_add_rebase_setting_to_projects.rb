# rubocop:disable all
class AddRebaseSettingToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :merge_requests_rebase_default, :boolean, default: true
  end
end
