# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class KnativeExternalIp < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    add_column :clusters_applications_knative, :external_ip, :string # rubocop:disable Migration/AddLimitToStringColumns
  end
end
