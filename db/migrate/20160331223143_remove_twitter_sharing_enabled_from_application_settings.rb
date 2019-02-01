# rubocop:disable all
class RemoveTwitterSharingEnabledFromApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    remove_column :application_settings, :twitter_sharing_enabled, :boolean
  end
end
