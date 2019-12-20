# frozen_string_literal: true

class AddGroupDeletionSchedules < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    create_table :group_deletion_schedules, id: false do |t|
      t.references :group,
        foreign_key: { on_delete: :cascade, to_table: :namespaces },
        default: nil,
        index: false,
        primary_key: true

      t.references :user,
        index: true,
        foreign_key: { on_delete: :nullify },
        null: false

      t.date :marked_for_deletion_on,
        index: true,
        null: false
    end
  end

  def down
    drop_table :group_deletion_schedules
  end
end
