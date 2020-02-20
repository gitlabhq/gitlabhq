# frozen_string_literal: true

class SaveInstanceAdministratorsGroupId < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  def up
    execute(
      <<-SQL
      UPDATE
        application_settings
      SET
        instance_administrators_group_id = (
          SELECT
            namespace_id
          FROM
            projects
          WHERE
            id = application_settings.instance_administration_project_id
        )
      WHERE
        instance_administrators_group_id IS NULL
        AND
        instance_administration_project_id IS NOT NULL
        AND
        ID in (
          SELECT
            max(id)
          FROM
            application_settings
        )
      SQL
    )
  end

  def down
    # no-op

    # The change performed by `up` cannot be reversed because once the migration runs,
    # we do not know what value application_settings.instance_administrators_group_id
    # had before the migration was run.
  end
end
