# frozen_string_literal: true

class DropUserInteractedProjectsTable < Gitlab::Database::Migration[2.2]
  milestone '16.10'

  def up
    # No-op https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17622
  end

  def down
    # No-op https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17622
  end
end
