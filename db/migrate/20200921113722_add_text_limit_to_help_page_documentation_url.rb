# frozen_string_literal: true

class AddTextLimitToHelpPageDocumentationUrl < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :help_page_documentation_base_url, 255
  end

  def down
    remove_text_limit :application_settings, :help_page_documentation_base_url
  end
end
