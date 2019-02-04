class AddHomePageUrlForApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :home_page_url, :string
  end
end
