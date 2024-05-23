# frozen_string_literal: true

class AddTextLimitOnRunnerName < Gitlab::Database::Migration[2.2]
  milestone '17.0'

  disable_ddl_transaction!

  def up
    add_text_limit :ci_runners, :name, 256, validate: false
  end

  def down
    # Down is required as `add_text_limit` is not reversible
    remove_text_limit :ci_runners, :name
  end
end
