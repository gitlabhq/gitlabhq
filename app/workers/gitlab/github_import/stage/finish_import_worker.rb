# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class FinishImportWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        # technical debt: https://gitlab.com/gitlab-org/gitlab/issues/33991
        sidekiq_options memory_killer_memory_growth_kb: ENV.fetch('MEMORY_KILLER_FINISH_IMPORT_WORKER_MEMORY_GROWTH_KB', 50).to_i
        sidekiq_options memory_killer_max_memory_growth_kb: ENV.fetch('MEMORY_KILLER_FINISH_IMPORT_WORKER_MAX_MEMORY_GROWTH_KB', 200_000).to_i

        # project - An instance of Project.
        def import(_, project)
          project.after_import
          report_import_time(project)
        end

        def report_import_time(project)
          duration = Time.zone.now - project.created_at

          histogram.observe({ project: project.full_path }, duration)
          counter.increment

          info(
            project.id,
            message: "GitHub project import finished",
            duration_s: duration.round(2),
            object_counts: ::Gitlab::GithubImport::ObjectCounter.summary(project)
          )
        end

        def histogram
          @histogram ||= Gitlab::Metrics.histogram(
            :github_importer_total_duration_seconds,
            'Total time spent importing GitHub projects, in seconds'
          )
        end

        def counter
          @counter ||= Gitlab::Metrics.counter(
            :github_importer_imported_projects,
            'The number of imported GitHub projects'
          )
        end
      end
    end
  end
end
