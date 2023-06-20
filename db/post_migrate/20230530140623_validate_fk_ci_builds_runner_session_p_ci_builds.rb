# frozen_string_literal: true

class ValidateFkCiBuildsRunnerSessionPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_builds_runner_session, nil, name: :temp_fk_rails_70707857d3_p
  end

  def down
    # no-op
  end
end
