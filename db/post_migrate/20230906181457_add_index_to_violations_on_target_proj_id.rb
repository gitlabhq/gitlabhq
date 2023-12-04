# frozen_string_literal: true

class AddIndexToViolationsOnTargetProjId < Gitlab::Database::Migration[2.1]
  TABLE_NAME = 'merge_requests_compliance_violations'
  # Use function based naming as suggested in docs:
  # https://docs.gitlab.com/ee/development/migration_style_guide.html#truncate-long-index-names
  INDEX_NAME = 'i_compliance_violations_for_export'

  def up
    prepare_async_index TABLE_NAME, [:target_project_id, :id], name: INDEX_NAME
  end

  def down
    unprepare_async_index TABLE_NAME, INDEX_NAME
  end
end
