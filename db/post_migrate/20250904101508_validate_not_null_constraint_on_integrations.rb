# frozen_string_literal: true

class ValidateNotNullConstraintOnIntegrations < Gitlab::Database::Migration[2.3]
  milestone '18.4'

  CONSTRAINT_NAME = 'check_2aae034509'

  def up
    # no-op
  end

  def down
    # no-op
  end
end
