module EE
  module Projects
    module HashedStorageMigrationService
      def execute
        raise NotImplementedError.new unless defined?(super)

        super do
          ::Geo::RepositoryRenamedEventStore.new(
            project,
            old_path: File.basename(old_disk_path),
            old_path_with_namespace: old_disk_path
          ).create
        end
      end
    end
  end
end
