# frozen_string_literal: true

class ChangeMaintainerNoteLimitInCiRunner < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit(
      :ci_runners,
      :maintainer_note,
      1024,
      constraint_name: check_constraint_name(:ci_runners, :maintainer_note, 'max_length_1MB')
    )

    remove_text_limit(
      :ci_runners,
      :maintainer_note,
      constraint_name: check_constraint_name(:ci_runners, :maintainer_note, 'max_length')
    )
  end

  def down
    # no-op: Danger of failing if there are records with length(maintainer_note) > 255
  end
end
