# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class ChangeClustersNamespacePerEnvironmentDefault < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def change
    change_column_default :clusters, :namespace_per_environment, from: false, to: true
  end
end
