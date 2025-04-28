# frozen_string_literal: true

class ValidateCiBuildNeedsProjectIdNotNull < Gitlab::Database::Migration[2.2]
  milestone '18.0'

  def up
    validate_not_null_constraint :ci_build_needs, :project_id, constraint_name: 'check_4fab85ecdc'
  end

  def down
    # no-op
  end
end
