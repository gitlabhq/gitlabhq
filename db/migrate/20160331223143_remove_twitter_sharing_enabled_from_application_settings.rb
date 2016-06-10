# rubocop:disable all
class RemoveTwitterSharingEnabledFromApplicationSettings < ActiveRecord::Migration
  def change
    remove_column :application_settings, :twitter_sharing_enabled, :boolean
  end
end
