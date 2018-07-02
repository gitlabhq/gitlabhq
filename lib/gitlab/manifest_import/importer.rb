module Gitlab
  module ManifestImport
    class Importer
      attr_reader :repository, :destination, :user

      def initialize(repository, destination, user)
        @repository = repository
        @destination = destination
        @user = user
      end

      def execute
        import_project
      end

      private

      def import_project
        group_full_path, _, project_path = repository[:path].rpartition('/')
        group_full_path = File.join(destination.path, group_full_path) if destination
        group = Group.find_by_full_path(group_full_path) ||
          create_group_with_parents(group_full_path)

        params = {
          import_url: repository[:url],
          import_type: 'manifest',
          namespace_id: group.id,
          path: project_path,
          name: project_path,
          visibility_level: destination.visibility_level
        }

        Projects::CreateService.new(user, params).execute
      end

      def create_group_with_parents(full_path)
        params = {
          group_path: full_path,
          visibility_level: destination.visibility_level
        }

        Groups::NestedCreateService.new(user, params).execute
      end
    end
  end
end
