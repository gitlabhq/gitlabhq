# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class FinishImportWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        # project - An instance of Project.
        def import(_, project)
          @project = project
          project.after_import
          report_import_time
        end

        private

        attr_reader :project

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
      end
    end
  end
end
