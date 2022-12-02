# frozen_string_literal: true

module QA
  module Runtime
    module API
      module RepositoryStorageMoves
        extend self
        extend Support::API

        RepositoryStorageMovesError = Class.new(RuntimeError)

        def has_status?(resource, status, destination_storage = Env.additional_repository_storage)
          find_any(resource) do |move|
            next unless resource_equals?(resource, move)

            QA::Runtime::Logger.debug("Move data: #{move}")

            move[:state] == status &&
              move[:destination_storage_name] == destination_storage
          end
        end

        def find_any(resource)
          Logger.debug('Getting repository storage moves')

          Support::Waiter.wait_until do
            get(Request.new(api_client, "/#{resource_name(resource)}_repository_storage_moves", per_page: '100').url) do |page|
              break true if page.any? { |item| yield item }
            end
          end
        end

        def resource_equals?(resource, move)
          if resource.class.name.include?('Snippet')
            move[:snippet][:id] == resource.id
          elsif resource.class.name.include?('Group')
            move[:group][:id] == resource.id
          else
            move[:project][:path_with_namespace] == resource.path_with_namespace
          end
        end

        def resource_name(resource)
          resource.class.name.split('::').last.downcase
        end

        private

        def api_client
          @api_client ||= Client.as_admin
        end
      end
    end
  end
end
