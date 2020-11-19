# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddHelmMajorVersionToClusters < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    add_column(:clusters, :helm_major_version, :integer, default: 2, null: false)
  end
end
