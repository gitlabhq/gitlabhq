# frozen_string_literal: true

class CreateObservabilityProjectO11ySettings < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def change
    create_table :observability_project_o11y_settings do |t|
      t.bigint :project_id, null: false
      # Note: uses `namespace_id` (not `group_id`) to align with the ongoing
      # group_id -> namespace migration (see
      # https://gitlab.com/gitlab-org/embody-team/experimental-observability/documentation/-/work_items/118).
      # The FK targets the same `namespaces` table as observability_group_o11y_settings.group_id.
      t.bigint :namespace_id, null: false
      t.bigint :created_by_id
      t.timestamps_with_timezone null: false
      t.boolean :enabled, null: false, default: true

      # Foreign keys are added in separate migrations per the migration style guide.
      t.index :project_id, unique: true
      t.index :namespace_id
      t.index :created_by_id
    end
  end
end
