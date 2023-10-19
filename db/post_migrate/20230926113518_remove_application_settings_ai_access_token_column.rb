# frozen_string_literal: true

class RemoveApplicationSettingsAiAccessTokenColumn < Gitlab::Database::Migration[2.1]
  def up
    # no-op because the column was not ignored correctly,
    # see https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/24523
  end

  def down
    # no-op because the column was not ignored correctly,
    # see https://gitlab.com/gitlab-com/gl-infra/reliability/-/issues/24523
  end
end
