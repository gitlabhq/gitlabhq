module EE
  module Projects
    module TransferService
      private

      def execute_system_hooks
        raise NotImplementedError unless defined?(super)

        super

        ::Geo::RepositoryRenamedEventStore.new(
          project,
          old_path: project.path,
          old_path_with_namespace: @old_path
        ).create
      end
    end
  end
end
