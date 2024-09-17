# frozen_string_literal: true

class DropWorkItemWidgetDefinitionsNamespaceId < Gitlab::Database::Migration[2.2]
  milestone '17.4'

  def up
    # no-op
    # Rescheduling migration as described in
    # https://gitlab.com/gitlab-org/gitlab/-/issues/480503
    # Making it safer to execute due to the locks that are required to acquire
  end

  def down
    # no-op
  end
end
