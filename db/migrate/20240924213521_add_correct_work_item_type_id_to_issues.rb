# frozen_string_literal: true

class AddCorrectWorkItemTypeIdToIssues < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    # Defaulting to 0 here to avoid validating the not null constraint afterwards as done in
    # https://gitlab.com/gitlab-org/gitlab/-/blob/a24ea906d46589c3397660eaf3223d5af6ad9708/lib/gitlab/database/migration_helpers.rb#L1182-1182
    # rubocop:disable Migration/PreventAddingColumns -- Legacy migration
    add_column :issues, :correct_work_item_type_id, :bigint, null: false, default: 0
    # rubocop:enable Migration/PreventAddingColumns
  end
end
