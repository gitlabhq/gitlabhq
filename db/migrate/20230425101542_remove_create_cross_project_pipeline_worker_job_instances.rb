# frozen_string_literal: true

class RemoveCreateCrossProjectPipelineWorkerJobInstances < Gitlab::Database::Migration[2.1]
  def up
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/9566
  end

  def down
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/9566
  end
end
