class AddHelpPageSupportUrlToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :application_settings, :help_page_support_url, :string
  end
end
