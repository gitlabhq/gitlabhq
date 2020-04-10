# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddJsonbToGeoNodeStatusTable < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_table :geo_node_statuses do |t|
      t.jsonb :status, null: false, default: {}
    end
  end
end
