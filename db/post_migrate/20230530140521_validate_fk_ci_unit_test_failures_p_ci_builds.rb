# frozen_string_literal: true

class ValidateFkCiUnitTestFailuresPCiBuilds < Gitlab::Database::Migration[2.1]
  def up
    validate_foreign_key :ci_unit_test_failures, nil, name: :temp_fk_9e0fc58930_p
  end

  def down
    # no-op
  end
end
