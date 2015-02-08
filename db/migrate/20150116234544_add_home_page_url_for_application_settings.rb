class AddHomePageUrlForApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :home_page_url, :string
  end
end
