# frozen_string_literal: true

class AddTextLimitOnRunnerDescription < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  disable_ddl_transaction!

  def up
    add_text_limit :ci_runners, :description, 1024, validate: false
  end

  def down
    # Down is required as `add_text_limit` is not reversible
    remove_text_limit :ci_runners, :description
  end
end
