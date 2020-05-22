# frozen_string_literal: true

class AddSpamCheckEndpointToApplicationSettings < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    unless column_exists?(:application_settings, :spam_check_endpoint_url)
      add_column :application_settings, :spam_check_endpoint_url, :text
    end

    add_text_limit :application_settings, :spam_check_endpoint_url, 255

    unless column_exists?(:application_settings, :spam_check_endpoint_enabled)
      add_column :application_settings, :spam_check_endpoint_enabled, :boolean, null: false, default: false
    end
  end

  def down
    remove_column_if_exists :spam_check_endpoint_url
    remove_column_if_exists :spam_check_endpoint_enabled
  end

  private

  def remove_column_if_exists(column)
    return unless column_exists?(:application_settings, column)

    remove_column :application_settings, column
  end
end
