# frozen_string_literal: true

class DropIssuesCorrectWorkItemTypeIdDefault < Gitlab::Database::Migration[2.2]
  milestone '17.7'

  def change
    change_column_default(:issues, :correct_work_item_type_id, from: 0, to: nil)
  end
end
