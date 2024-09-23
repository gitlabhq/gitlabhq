# frozen_string_literal: true

class ValidateCiRunnersDescriptionTextLimit < Gitlab::Database::Migration[2.2]
  milestone '17.5'
  disable_ddl_transaction!

  def up
    validate_text_limit :ci_runners, :description
  end

  def down
    # no-op
  end
end
