class HelpTextToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :help_text, :text
  end
end
