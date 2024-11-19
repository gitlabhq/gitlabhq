# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class FinishImportWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        # project - An instance of Project.
        def import(_, project)
          @project = project

          return self.class.perform_in(30.seconds, project.id) if reference_store_pending?

          project.after_import

          report_import_time
        end

        private

        attr_reader :project

        def reference_store_pending?
          return false unless import_settings(project).user_mapping_enabled?

          return false unless placeholder_reference_store.any?

          ::Import::LoadPlaceholderReferencesWorker.perform_async(
            ::Import::SOURCE_GITHUB,
            project.import_state.id,
            { 'current_user_id' => project.creator.id }
          )

          info(
            project.id,
            message: 'Delaying finalization as placeholder references are pending',
            placeholder_store_count: placeholder_reference_store.count
          )

          true
        end

        def report_import_time
          metrics.track_finished_import

          info(
            project.id,
            message: "GitHub project import finished",
            duration_s: metrics.duration.round(2),
            object_counts: ::Gitlab::GithubImport::ObjectCounter.summary(project)
          )
        end

        def metrics
          @metrics ||= Gitlab::Import::Metrics.new(:github_importer, project)
        end

        def placeholder_reference_store
          @placeholder_reference_store ||= project.placeholder_reference_store
        end
      end
    end
  end
end
