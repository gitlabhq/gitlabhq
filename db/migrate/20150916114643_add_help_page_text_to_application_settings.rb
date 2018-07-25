class AddHelpPageTextToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :help_page_text, :text
  end
end
