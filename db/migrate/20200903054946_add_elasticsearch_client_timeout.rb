# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddElasticsearchClientTimeout < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column :application_settings, :elasticsearch_client_request_timeout, :integer, null: false, default: 0
  end
end
