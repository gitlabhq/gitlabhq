# frozen_string_literal: true

class ValidateFkCiPendingBuildsPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_pending_builds, nil, name: :temp_fk_rails_725a2644a3_p
  end

  def down
    # no-op
  end
end
