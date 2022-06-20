# frozen_string_literal: true

module FileStoreMounter
  extend ActiveSupport::Concern

  class_methods do
    # When `skip_store_file: true` is used, the model MUST explicitly call `store_file_now!`
    def mount_file_store_uploader(uploader, skip_store_file: false)
      mount_uploader(:file, uploader)

      if skip_store_file
        skip_callback :save, :after, :store_file!

        return
      end

      # This hook is a no-op when the file is uploaded after_commit
      after_save :update_file_store, if: :saved_change_to_file?
    end
  end

  def update_file_store
    # The file.object_store is set during `uploader.store!` and `uploader.migrate!`
    update_column(:file_store, file.object_store)
  end

  def store_file_now!
    store_file!
    update_file_store
  end
end
