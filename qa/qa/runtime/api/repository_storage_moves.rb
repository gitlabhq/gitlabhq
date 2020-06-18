# frozen_string_literal: true

module QA
  module Runtime
    module API
      module RepositoryStorageMoves
        extend self
        extend Support::Api

        RepositoryStorageMovesError = Class.new(RuntimeError)

        def has_status?(project, status, destination_storage = Env.additional_repository_storage)
          all.any? do |move|
            move[:project][:path_with_namespace] == project.path_with_namespace &&
            move[:state] == status &&
            move[:destination_storage_name] == destination_storage
          end
        end

        def all
          Logger.debug('Getting repository storage moves')
          parse_body(get(Request.new(api_client, '/project_repository_storage_moves').url))
        end

        private

        def api_client
          @api_client ||= Client.as_admin
        end
      end
    end
  end
end
