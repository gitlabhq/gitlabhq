# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddModsecurityEnabledToIngressApplication < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    add_column :clusters_applications_ingress, :modsecurity_enabled, :boolean
  end

  def down
    remove_column :clusters_applications_ingress, :modsecurity_enabled
  end
end
