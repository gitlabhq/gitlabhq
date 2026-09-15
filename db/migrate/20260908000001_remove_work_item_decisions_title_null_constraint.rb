# frozen_string_literal: true

class RemoveWorkItemDecisionsTitleNullConstraint < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  def up
    change_column_null :work_item_decisions, :title, true
  end

  def down
    change_column_null :work_item_decisions, :title, false
  end
end
