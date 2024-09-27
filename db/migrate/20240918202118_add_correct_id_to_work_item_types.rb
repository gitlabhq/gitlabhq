# frozen_string_literal: true

class AddCorrectIdToWorkItemTypes < Gitlab::Database::Migration[2.2]
  milestone '17.5'

  def change
    # Defaulting to 0 here to avoid validating the not null constraint afterwards as done in
    # https://gitlab.com/gitlab-org/gitlab/-/blob/a24ea906d46589c3397660eaf3223d5af6ad9708/lib/gitlab/database/migration_helpers.rb#L1182-1182
    # Then, we can even delete records that are not changed by the following migration as those records, if any,
    # should not exist. Then we can add the FK and be confident the records in work_item_types table are correct
    add_column :work_item_types, :correct_id, :bigint, null: false, default: 0
  end
end
