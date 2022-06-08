# frozen_string_literal: true

class AddTextLimitToCiRunnersSemver < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_text_limit :ci_runners, :semver, 16
  end

  def down
    remove_text_limit :ci_runners, :semver
  end
end
