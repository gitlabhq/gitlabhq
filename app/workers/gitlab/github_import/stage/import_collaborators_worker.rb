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
          return move_to_next_stage(project, {}) unless import_collaborators?(project)

          unless has_push_access?(client, project.import_source)
            log_no_push_access(project)
            return move_to_next_stage(project, {})
          end

          info(project.id, message: 'starting importer', importer: 'Importer::CollaboratorsImporter')

          waiter = Importer::CollaboratorsImporter.new(project, client).execute

          move_to_next_stage(project, { waiter.key => waiter.jobs_remaining })
        end

        private

        def import_collaborators?(project)
          import_settings = import_settings(project)
          return false if import_settings.disabled?(:collaborators_import)
          return false if import_settings.map_to_personal_namespace_owner?

          ::Import::MemberLimitCheckService.new(project).execute.success?
        end

        def has_push_access?(client, repo)
          client.repository(repo).dig(:permissions, :push)
        end

        def log_no_push_access(project)
          Gitlab::GithubImport::Logger.warn(
            log_attributes(
              project.id,
              message: 'no push access rights to fetch collaborators',
              importer: 'Importer::CollaboratorsImporter'
            )
          )
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
