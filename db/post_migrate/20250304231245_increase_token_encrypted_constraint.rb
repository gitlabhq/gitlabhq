# frozen_string_literal: true

class IncreaseTokenEncryptedConstraint < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.10'

  P_TABLE_NAME = 'ci_runners_e59bb2812d'

  def up
    # rubocop:disable Layout/LineLength -- This is more readable
    # Use the partitioned table name for the constraint name to ensure consistency.
    add_text_limit table_name, :token_encrypted, 512, constraint_name: check_constraint_name(P_TABLE_NAME, :token_encrypted, 'max_length_512')
    remove_text_limit table_name, :token_encrypted, constraint_name: check_constraint_name(P_TABLE_NAME, :token_encrypted, 'max_length')
    # rubocop:enable Layout/LineLength
  end

  def down
    # no-op: Danger of failing if there are records with length(token_encrypted) > 128
  end

  private

  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/182549 renamed ci_runners_e59bb2812d to ci_runners,
  # but then it was reverted in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/183389. That
  # means some environments no longer have ci_runners_e59bb2812d, but they do have ci_runners.
  # Fall back to fixing the constraint for ci_runners in that case.
  def table_name
    @table_name ||= table_exists?(P_TABLE_NAME) ? P_TABLE_NAME : 'ci_runners'
  end
end
