# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class RemoveNotNullFromExternalDashboardUrl < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def change
    change_column_null :project_metrics_settings, :external_dashboard_url, true
  end
end
