# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportNotesWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        sidekiq_options retry: 3
        include GithubImport::Queue
        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          waiters = importers(project).each_with_object({}) do |klass, hash|
            info(project.id, message: "starting importer", importer: klass.name)
            waiter = klass.new(project, client).execute
            hash[waiter.key] = waiter.jobs_remaining
          end

          AdvanceStageWorker.perform_async(
            project.id,
            waiters,
            :lfs_objects
          )
        end

        def importers(project)
          if project.group.present? && Feature.enabled?(:github_importer_single_endpoint_notes_import, project.group, type: :ops, default_enabled: :yaml)
            [
              Importer::SingleEndpointMergeRequestNotesImporter,
              Importer::SingleEndpointIssueNotesImporter
            ]
          else
            [
              Importer::NotesImporter
            ]
          end
        end
      end
    end
  end
end
