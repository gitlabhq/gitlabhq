# frozen_string_literal: true

class ValidateFkCiBuildPendingStatesPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_build_pending_states, nil, name: :temp_fk_861cd17da3_p
  end

  def down
    # no-op
  end
end
