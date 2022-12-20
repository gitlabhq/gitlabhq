# frozen_string_literal: true

class ChangeVulnerabilitiesStateTransitionsCommentLimit < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit(
      :vulnerability_state_transitions,
      :comment,
      50_000,
      constraint_name: check_constraint_name(:vulnerability_state_transitions, :comment, 'max_length_50000')
    )
    remove_text_limit(
      :vulnerability_state_transitions,
      :comment,
      constraint_name: 'check_fca4a7ca39'
    )
  end

  def down
    # no-op: this can fail if records with length > 255 (previous limit) show up
  end
end
