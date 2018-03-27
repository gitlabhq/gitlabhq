# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class FinishImportWorker
        include ApplicationWorker
        include GithubImport::Queue
        include StageMethods

        # project - An instance of Project.
        def import(_, project)
          project.after_import
          report_import_time(project)
        end

        def report_import_time(project)
          duration = Time.zone.now - project.created_at
          path = project.full_path

          histogram.observe({ project: path }, duration)
          counter.increment

          logger.info("GitHub importer finished for #{path} in #{duration.round(2)} seconds")
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
