# frozen_string_literal: true

class RemoveCreateLearnGitlabWorkerJobInstances < Gitlab::Database::Migration[2.1]
  def up
    # No-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8612
  end

  def down
    # No-op to fix https://gitlab.com/gitlab-com/gl-infra/production/-/issues/8612
  end
end
