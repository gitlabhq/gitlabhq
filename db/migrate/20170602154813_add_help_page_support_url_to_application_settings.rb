class AddHelpPageSupportUrlToApplicationSettings < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :help_page_support_url, :string
  end
end
