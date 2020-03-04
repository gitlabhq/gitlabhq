# frozen_string_literal: true

class CleanGrafanaUrl < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute(
      <<-SQL
      UPDATE
        application_settings
      SET
        grafana_url = default
      WHERE
        position('javascript:' IN btrim(application_settings.grafana_url)) = 1
      SQL
    )
  end

  def down
    # no-op
  end
end
