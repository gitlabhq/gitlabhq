# frozen_string_literal: true

class SanitizeConfidentialNoteTodos < Gitlab::Database::Migration[2.0]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op: this empty migration is left here only for compatibility reasons.
    # It was a temporary migration which used not-isolated code.
    # https://gitlab.com/gitlab-org/gitlab/-/issues/382557
  end

  def down
    # no-op
  end
end
