# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class RegistryRepository < Base
      attr_accessor :name,
                    :repository_id

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'project-with-registry'
          resource.description = 'Project with Registry'
        end
      end

      def initialize
        @name = project.path_with_namespace
        @repository_id = nil
      end

      def fabricate!
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def remove_via_api!
        registry_repositories = project.registry_repositories
        if registry_repositories && !registry_repositories.empty?
          this_registry_repository = registry_repositories.find { |registry_repository| registry_repository[:path] == name }

          @repository_id = this_registry_repository[:id]

          QA::Runtime::Logger.debug("Deleting registry '#{name}'")
          super
        end
      end

      def api_delete_path
        "/projects/#{project.id}/registry/repositories/#{@repository_id}"
      end

      def api_get_path
        "/projects/#{project.id}/registry/repositories"
      end
    end
  end
end
