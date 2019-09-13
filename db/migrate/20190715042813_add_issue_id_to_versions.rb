# frozen_string_literal: true

class AddIssueIdToVersions < ActiveRecord::Migration[5.2]
  DOWNTIME = false

  def up
    # rubocop:disable Migration/AddReference
    add_reference :design_management_versions, :issue, index: true, foreign_key: { on_delete: :cascade }
    # rubocop:enable Migration/AddReference
  end

  def down
    remove_reference :design_management_versions, :issue
  end
end
