module EE
  module Projects
    module HashedStorage
      module MigrateAttachmentsService
        extend ::Gitlab::Utils::Override

        override :execute
        def execute
          super do
            ::Geo::HashedStorageAttachmentsEventStore.new(
              project,
              old_attachments_path: old_disk_path,
              new_attachments_path: new_disk_path
            ).create
          end
        end
      end
    end
  end
end
