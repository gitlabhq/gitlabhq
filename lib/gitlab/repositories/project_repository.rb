# frozen_string_literal: true

module Gitlab
  module Repositories
    class ProjectRepository < Gitlab::Repositories::RepoType
      include Singleton
      extend Gitlab::Utils::Override

      override :name
      def name
        :project
      end

      override :access_checker_class
      def access_checker_class
        Gitlab::GitAccessProject
      end

      override :guest_read_ability
      def guest_read_ability
        :download_code
      end

      override :container_class
      def container_class
        Project
      end

      override :project_for
      def project_for(container)
        container
      end

      private

      override :repository_resolver
      def repository_resolver(project)
        ::Repository.new(
          project.full_path,
          project,
          shard: project.repository_storage,
          disk_path: project.disk_path
        )
      end

      override :check_container
      def check_container(container)
        # Don't check container for projects because it accepts several container types.
      end
    end
  end
end
