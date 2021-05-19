# frozen_string_literal: true

class AddTextLimitToElasticsearchUsername < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  def up
    add_text_limit :application_settings, :elasticsearch_username, 255
  end

  def down
    remove_text_limit :application_settings, :elasticsearch_username
  end
end
