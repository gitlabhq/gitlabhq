# frozen_string_literal: true

class RemoveDuplicateLabelsFromProject < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  CREATE = 1
  RENAME = 2

  disable_ddl_transaction!

  class BackupLabel < Label
    self.inheritance_column = :_type_disabled

    self.table_name = 'backup_labels'
  end

  class Label < ApplicationRecord
    self.table_name = 'labels'
  end

  class Project < ApplicationRecord
    include EachBatch

    self.table_name = 'projects'
  end

  BATCH_SIZE = 100_000

  def up
    # Split to smaller chunks
    # Loop rather than background job, every 100,000
    # there are 45,000,000 projects in total
    Project.each_batch(of: BATCH_SIZE) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      transaction do
        remove_full_duplicates(*range)
      end

      transaction do
        rename_partial_duplicates(*range)
      end
    end
  end

  def down
    Project.each_batch(of: BATCH_SIZE) do |batch|
      range = batch.pluck('MIN(id)', 'MAX(id)').first

      restore_renamed_labels(*range)
      restore_deleted_labels(*range)
    end
  end

  def remove_full_duplicates(start_id, stop_id)
    # Fields that are considered duplicate:
    # project_id title template description type color

    duplicate_labels = ApplicationRecord.connection.execute(<<-SQL.squish)
WITH data AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
  SELECT labels.*,
  row_number() OVER (PARTITION BY labels.project_id, labels.title, labels.template, labels.description, labels.type, labels.color ORDER BY labels.id) AS row_number,
  #{CREATE} AS restore_action
  FROM labels
  WHERE labels.project_id BETWEEN #{start_id} AND #{stop_id}
  AND NOT EXISTS (SELECT * FROM board_labels WHERE board_labels.label_id = labels.id)
  AND NOT EXISTS (SELECT * FROM label_links WHERE label_links.label_id = labels.id)
  AND NOT EXISTS (SELECT * FROM label_priorities WHERE label_priorities.label_id = labels.id)
  AND NOT EXISTS (SELECT * FROM lists WHERE lists.label_id = labels.id)
  AND NOT EXISTS (SELECT * FROM resource_label_events WHERE resource_label_events.label_id = labels.id)
) SELECT * FROM data WHERE row_number > 1;
    SQL

    if duplicate_labels.any?
      # create backup records
      BackupLabel.insert_all!(duplicate_labels.map { |label| label.except("row_number") })

      Label.where(id: duplicate_labels.pluck("id")).delete_all
    end
  end

  def rename_partial_duplicates(start_id, stop_id)
    # We need to ensure that the new title (with `_duplicate#{ID}`) doesn't exceed the limit.
    # Truncate the original title (if needed) to 245 characters minus the length of the ID
    # then add `_duplicate#{ID}`

    soft_duplicates = ApplicationRecord.connection.execute(<<-SQL.squish)
WITH data AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
  SELECT
     *,
     substring(title from 1 for 245 - length(id::text)) || '_duplicate' || id::text as new_title,
     #{RENAME} AS restore_action,
     row_number() OVER (PARTITION BY project_id, title ORDER BY id) AS row_number
  FROM labels
  WHERE project_id BETWEEN #{start_id} AND #{stop_id}
) SELECT * FROM data WHERE row_number > 1;
    SQL

    if soft_duplicates.any?
      # create backup records
      BackupLabel.insert_all!(soft_duplicates.map { |label| label.except("row_number") })

      ApplicationRecord.connection.execute(<<-SQL.squish)
UPDATE labels SET title = substring(title from 1 for 245 - length(id::text)) || '_duplicate' || id::text
WHERE labels.id IN (#{soft_duplicates.map { |dup| dup["id"] }.join(", ")});
      SQL
    end
  end

  def restore_renamed_labels(start_id, stop_id)
    # the backup label IDs are not incremental, they are copied directly from the Labels table
    ApplicationRecord.connection.execute(<<-SQL.squish)
WITH backups AS #{Gitlab::Database::AsWithMaterialized.materialized_if_supported} (
  SELECT id, title
  FROM backup_labels
  WHERE project_id BETWEEN #{start_id} AND #{stop_id} AND
  restore_action = #{RENAME}
) UPDATE labels SET title = backups.title
FROM backups
WHERE labels.id = backups.id;
    SQL
  end

  def restore_deleted_labels(start_id, stop_id)
    ActiveRecord::Base.connection.execute(<<-SQL.squish)
INSERT INTO labels
SELECT id, title, color, project_id, created_at, updated_at, template, description, description_html, type, group_id, cached_markdown_version FROM backup_labels
  WHERE backup_labels.project_id BETWEEN #{start_id} AND #{stop_id}
  AND backup_labels.restore_action = #{CREATE}
    SQL
  end
end
