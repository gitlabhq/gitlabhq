# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Stage
      class FinishImportWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        def import(project)
          project.after_import

          Gitlab::Import::Metrics.new(:bitbucket_importer, project).track_finished_import
        end
      end
    end
  end
end
