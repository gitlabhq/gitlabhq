# frozen_string_literal: true

class AddTextLimitToCiRunnerTaggingsName < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'ci_runner_taggings_name_length'

  def up
    add_text_limit :ci_runner_taggings, :name, 1000, constraint_name: CONSTRAINT_NAME
  end

  def down
    # Down is required as `add_text_limit` is not reversible
    remove_text_limit :ci_runner_taggings, :name, constraint_name: CONSTRAINT_NAME
  end
end
