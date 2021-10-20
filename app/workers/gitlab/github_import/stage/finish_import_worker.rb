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

        # technical debt: https://gitlab.com/gitlab-org/gitlab/issues/33991
        sidekiq_options memory_killer_memory_growth_kb: ENV.fetch('MEMORY_KILLER_FINISH_IMPORT_WORKER_MEMORY_GROWTH_KB', 50).to_i
        sidekiq_options memory_killer_max_memory_growth_kb: ENV.fetch('MEMORY_KILLER_FINISH_IMPORT_WORKER_MAX_MEMORY_GROWTH_KB', 200_000).to_i

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
