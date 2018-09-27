module Geo
  class LfsObjectDeletedEventStore < EventStore
    extend ::Gitlab::Utils::Override

    self.event_type = :lfs_object_deleted_event

    attr_reader :lfs_object

    def initialize(lfs_object)
      @lfs_object = lfs_object
    end

    override :create!
    def create!
      return unless lfs_object.local_store?

      super
    end

    private

    def build_event
      Geo::LfsObjectDeletedEvent.new(
        lfs_object: lfs_object,
        oid: lfs_object.oid,
        file_path: relative_file_path
      )
    end

    def local_store_path
      Pathname.new(LfsObjectUploader.root)
    end

    def relative_file_path
      return unless lfs_object.file.present?

      Pathname.new(lfs_object.file.path).relative_path_from(local_store_path)
    end

    # This is called by ProjectLogHelpers to build json log with context info
    #
    # @see ::Gitlab::Geo::ProjectLogHelpers
    def base_log_data(message)
      {
        class: self.class.name,
        lfs_object_id: lfs_object.id,
        file_path: lfs_object.file.path,
        message: message
      }
    end
  end
end
