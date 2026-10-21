# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Stage
      # Bitbucket Cloud no longer offers an issue API, so issues are not imported.
      # Kept so imports in flight during the deploy can still advance. See
      # https://gitlab.com/gitlab-org/gitlab/-/work_items/601064
      class ImportIssuesWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        # project - An instance of Project.
        def import(project)
          AdvanceStageWorker.perform_async(project.id, {}, :lfs_objects)
        end
      end
    end
  end
end
