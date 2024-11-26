# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Stage
      class FinishImportWorker # rubocop:disable Scalability/IdempotentWorker
        include StageMethods

        PLACEHOLDER_WAIT_INTERVAL = 30.seconds

        private

        # @param project [Project]
        def import(project)
          placeholder_reference_store = project.placeholder_reference_store

          if placeholder_reference_store&.any?
            info(
              project.id,
              message: 'Delaying finalization as placeholder references are pending',
              placeholder_store_count: placeholder_reference_store.count
            )

            reschedule(project)

            return
          end

          project.after_import

          Gitlab::Import::Metrics.new(:bitbucket_server_importer, project).track_finished_import
        end

        def reschedule(project)
          ::Import::LoadPlaceholderReferencesWorker.perform_async(
            project.import_type,
            project.import_state.id,
            { current_user_id: project.creator_id }
          )

          self.class.perform_in(PLACEHOLDER_WAIT_INTERVAL.seconds, project.id)
        end
      end
    end
  end
end
