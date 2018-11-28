# rubocop:disable all
class AddEmailAuthorInBodyToApplicationSettings < ActiveRecord::Migration[4.2]
  def change
    add_column :application_settings, :email_author_in_body, :boolean, default: false
  end
end
