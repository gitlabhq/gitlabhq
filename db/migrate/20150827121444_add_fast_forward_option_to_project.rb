# rubocop:disable all
class AddFastForwardOptionToProject < ActiveRecord::Migration
  def change
    add_column :projects, :merge_requests_ff_only_enabled, :boolean, default: false
  end
end
