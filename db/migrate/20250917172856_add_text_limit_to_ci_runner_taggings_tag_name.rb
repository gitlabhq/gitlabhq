# frozen_string_literal: true

class AddTextLimitToCiRunnerTaggingsTagName < Gitlab::Database::Migration[2.3]
  milestone '18.5'

  disable_ddl_transaction!

  CONSTRAINT_NAME = 'ci_runner_taggings_tag_name_length'

  def up
    add_text_limit :ci_runner_taggings, :tag_name, 1024, constraint_name: CONSTRAINT_NAME
  end

  def down
    # Down is required as `add_text_limit` is not reversible
    remove_text_limit :ci_runner_taggings, :tag_name, constraint_name: CONSTRAINT_NAME
  end
end
