# frozen_string_literal: true

class ValidateNotNullConstraintOnCiBuildNeedsProjectId < Gitlab::Database::Migration[2.3]
  milestone '18.6'

  def up
    # NOTE: constraint was added in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/184429/diffs
    validate_not_null_constraint(:ci_build_needs, :project_id, constraint_name: :check_4fab85ecdc)
  end

  def down
    # no-op
  end
end
