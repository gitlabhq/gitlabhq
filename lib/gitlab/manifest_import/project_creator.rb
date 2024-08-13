# frozen_string_literal: true

module Gitlab
  module ManifestImport
    class ProjectCreator
      attr_reader :repository, :destination, :current_user

      def initialize(repository, destination, current_user)
        @repository = repository
        @destination = destination
        @current_user = current_user
      end

      def execute
        group_full_path, _, project_path = repository[:path].rpartition('/')
        group_full_path = File.join(destination.full_path, group_full_path) if destination
        group = create_group_with_parents(group_full_path)

        params = {
          import_url: repository[:url],
          import_source: repository[:url],
          import_type: 'manifest',
          namespace_id: group.id,
          organization_id: group.organization_id,
          path: project_path,
          name: project_path,
          visibility_level: destination.visibility_level
        }

        Projects::CreateService.new(current_user, params).execute
      end

      private

      def create_group_with_parents(full_path)
        params = {
          group_path: full_path,
          visibility_level: destination.visibility_level,
          organization_id: destination.organization_id
        }

        Groups::NestedCreateService.new(current_user, params).execute
      end
    end
  end
end
