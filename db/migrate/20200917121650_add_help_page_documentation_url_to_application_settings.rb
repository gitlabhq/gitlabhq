# frozen_string_literal: true

class AddHelpPageDocumentationUrlToApplicationSettings < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  # rubocop:disable Migration/AddLimitToTextColumns
  # limit is added in 20200921113722_add_text_limit_to_help_page_documentation_url.rb
  def change
    add_column :application_settings, :help_page_documentation_base_url, :text
  end
  # rubocop:enable Migration/AddLimitToTextColumns
end
