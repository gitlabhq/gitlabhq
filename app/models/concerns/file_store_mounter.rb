# frozen_string_literal: true

module FileStoreMounter
  extend ActiveSupport::Concern

  class_methods do
    def mount_file_store_uploader(uploader)
      mount_uploader(:file, uploader)

      # This hook is a no-op when the file is uploaded after_commit
      after_save :update_file_store, if: :saved_change_to_file?
    end
  end

  def update_file_store
    # The file.object_store is set during `uploader.store!` and `uploader.migrate!`
    update_column(:file_store, file.object_store)
  end
end
