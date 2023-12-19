# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportAttachmentsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        resumes_work_when_interrupted!

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          return skip_to_next_stage(project) if import_settings(project).disabled?(:attachments_import)

          waiters = importers.each_with_object({}) do |importer, hash|
            waiter = start_importer(project, importer, client)
            hash[waiter.key] = waiter.jobs_remaining
          end
          move_to_next_stage(project, waiters)
        end

        private

        # For future issue/mr/milestone/etc attachments importers
        def importers
          [
            ::Gitlab::GithubImport::Importer::Attachments::ReleasesImporter,
            ::Gitlab::GithubImport::Importer::Attachments::NotesImporter,
            ::Gitlab::GithubImport::Importer::Attachments::IssuesImporter,
            ::Gitlab::GithubImport::Importer::Attachments::MergeRequestsImporter
          ]
        end

        def start_importer(project, importer, client)
          info(project.id, message: "starting importer", importer: importer.name)
          importer.new(project, client).execute
        end

        def skip_to_next_stage(project)
          info(project.id, message: "skipping importer", importer: 'Attachments')
          move_to_next_stage(project)
        end

        def move_to_next_stage(project, waiters = {})
          AdvanceStageWorker.perform_async(
            project.id,
            waiters.deep_stringify_keys,
            'protected_branches'
          )
        end
      end
    end
  end
end
