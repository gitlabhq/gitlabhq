# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Stage
      class FinishImportWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        private

        # project - An instance of Project.
        def import(project)
          project.after_import

          Gitlab::Import::Metrics.new(:bitbucket_server_importer, project).track_finished_import
        end
      end
    end
  end
end
