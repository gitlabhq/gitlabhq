# frozen_string_literal: true

class AddTextLimitToCiRunnersMaintainerNote < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :ci_runners, :maintainer_note, 255
  end

  def down
    remove_text_limit :ci_runners, :maintainer_note
  end
end
