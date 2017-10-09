class AddRepositoryStorageToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :repository_storage, :string, default: 'default'
  end
end
