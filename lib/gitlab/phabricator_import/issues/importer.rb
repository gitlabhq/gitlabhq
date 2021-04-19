# frozen_string_literal: true
module Gitlab
  module PhabricatorImport
    module Issues
      class Importer
        def initialize(project, after = nil)
          @project = project
          @after = after
        end

        def execute
          schedule_next_batch

          tasks_response.tasks.each do |task|
            TaskImporter.new(project, task).execute
          end
        end

        private

        attr_reader :project, :after

        def schedule_next_batch
          return unless tasks_response.pagination.has_next_page?

          Gitlab::PhabricatorImport::ImportTasksWorker
            .schedule(project.id, tasks_response.pagination.next_page)
        end

        def tasks_response
          @tasks_response ||= client.tasks(after: after)
        end

        def client
          @client ||=
            Gitlab::PhabricatorImport::Conduit::Maniphest
              .new(phabricator_url: project.import_data.data['phabricator_url'],
                   api_token: project.import_data.credentials[:api_token])
        end
      end
    end
  end
end
