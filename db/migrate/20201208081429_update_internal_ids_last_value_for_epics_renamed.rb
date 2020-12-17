# frozen_string_literal: true

class UpdateInternalIdsLastValueForEpicsRenamed < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    ApplicationRecord.connection.execute(<<-SQL.squish)
      UPDATE internal_ids
      SET last_value = epics_max_iids.maximum_iid
      FROM
        (
          SELECT
            MAX(epics.iid) AS maximum_iid,
            epics.group_id AS epics_group_id
          FROM epics
          GROUP BY epics.group_id
        ) epics_max_iids
      WHERE internal_ids.last_value < epics_max_iids.maximum_iid
        AND namespace_id = epics_max_iids.epics_group_id
        AND internal_ids.usage = 4
    SQL
  end

  def down
    # no-op
  end
end
