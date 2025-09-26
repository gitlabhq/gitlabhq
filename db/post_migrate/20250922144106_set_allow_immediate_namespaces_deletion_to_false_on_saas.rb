# frozen_string_literal: true

class SetAllowImmediateNamespacesDeletionToFalseOnSaas < Gitlab::Database::Migration[2.3]
  milestone '18.5'
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    # no-op - https://gitlab.com/gitlab-org/gitlab/-/issues/572480
  end

  def down
    # no-op
  end
end
