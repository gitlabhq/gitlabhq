# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class CreateCiBuildsConfig < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :ci_builds_config, id: :bigserial do |t|
      t.integer :build_id, index: true
      t.text :yaml_options
      t.text :yaml_variables
    end
  end
end
