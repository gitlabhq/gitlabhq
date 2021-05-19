# frozen_string_literal: true

class AddElasticsearchUsernamePasswordToApplicationSettings < ActiveRecord::Migration[6.0]
  def change
    # rubocop:disable Migration/AddLimitToTextColumns
    # limit is added in 20210505124816_add_text_limit_to_elasticsearch_username
    add_column :application_settings, :elasticsearch_username, :text
    # rubocop:enable Migration/AddLimitToTextColumns

    add_column :application_settings, :encrypted_elasticsearch_password, :binary
    add_column :application_settings, :encrypted_elasticsearch_password_iv, :binary
  end
end
