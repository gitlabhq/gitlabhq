# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Stage
      class ImportCollaboratorsWorker # rubocop:disable Scalability/IdempotentWorker
        include ApplicationWorker

        data_consistency :always

        include StageMethods

        # client - An instance of Gitlab::GithubImport::Client.
        # project - An instance of Project.
        def import(client, project)
          return skip_to_next_stage(project) if import_settings(project).disabled?(:collaborators_import) ||
            !has_push_access?(client, project.import_source)

          info(project.id, message: 'starting importer', importer: 'Importer::CollaboratorsImporter')

          waiter = Importer::CollaboratorsImporter.new(project, client).execute

          move_to_next_stage(project, { waiter.key => waiter.jobs_remaining })
        end

        private

        def has_push_access?(client, repo)
          client.repository(repo).dig(:permissions, :push)
        end

        def skip_to_next_stage(project)
          Gitlab::GithubImport::Logger.warn(
            log_attributes(
              project.id,
              message: 'no push access rights to fetch collaborators',
              importer: 'Importer::CollaboratorsImporter'
            )
          )
          move_to_next_stage(project, {})
        end

        def move_to_next_stage(project, waiters = {})
          AdvanceStageWorker.perform_async(
            project.id, waiters.deep_stringify_keys, 'issues_and_diff_notes'
          )
        end
      end
    end
  end
end
