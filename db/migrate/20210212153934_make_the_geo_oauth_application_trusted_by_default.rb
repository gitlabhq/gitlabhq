# frozen_string_literal: true

class MakeTheGeoOauthApplicationTrustedByDefault < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute(<<-SQL.squish)
      UPDATE oauth_applications
      SET confidential = true, trusted = true
      WHERE id IN (SELECT oauth_application_id FROM geo_nodes);
    SQL
  end

  def down
    # We won't be able to tell which trusted applications weren't
    # confidential before the migration and setting all trusted
    # applications are not confidential would introduce security
    # issues.
  end
end
