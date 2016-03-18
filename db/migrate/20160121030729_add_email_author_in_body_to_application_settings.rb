class AddEmailAuthorInBodyToApplicationSettings < ActiveRecord::Migration
  def change
    add_column :application_settings, :email_author_in_body, :boolean, default: false
  end
end
