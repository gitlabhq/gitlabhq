# frozen_string_literal: true

class DropMemberTasksTable < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # no-op to resolve https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16991
  end

  def down
    # no-op to resolve https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16991
  end
end
