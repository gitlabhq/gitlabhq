# frozen_string_literal: true

class PrepareRemovalIndexNotesOnIdWhereConfidential < Gitlab::Database::Migration[2.3]
  milestone '18.11'

  INDEX_NAME = 'index_notes_on_id_where_confidential'

  def up
    # Follow-up issue to remove index https://gitlab.com/gitlab-org/gitlab/-/work_items/595594
    prepare_async_index_removal :notes, :id, name: INDEX_NAME
  end

  def down
    unprepare_async_index_by_name :notes, INDEX_NAME
  end
end
