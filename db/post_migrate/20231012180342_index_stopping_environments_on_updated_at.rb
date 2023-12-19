# frozen_string_literal: true

class IndexStoppingEnvironmentsOnUpdatedAt < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'index_environments_on_updated_at_for_stopping_state'

  # TODO: Index to be created synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/428069
  def up
    prepare_async_index :environments, %i[updated_at], where: "state = 'stopping'", name: INDEX_NAME
  end

  def down
    unprepare_async_index :environments, %i[updated_at], where: "state = 'stopping'", name: INDEX_NAME
  end
end
