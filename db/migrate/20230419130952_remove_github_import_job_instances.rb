# frozen_string_literal: true

class RemoveGithubImportJobInstances < Gitlab::Database::Migration[2.1]
  def up
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/9300
  end

  def down
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/9300
  end
end
