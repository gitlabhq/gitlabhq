# frozen_string_literal: true

module FileStoreMounter
  ALLOWED_FILE_FIELDS = %i[file signed_file].freeze

  extend ActiveSupport::Concern

  class_methods do
    # When `skip_store_file: true` is used, the model MUST explicitly call `store_#{file_field}_now!`
    def mount_file_store_uploader(uploader, skip_store_file: false, file_field: :file)
      raise ArgumentError, "file_field not allowed: #{file_field}" unless ALLOWED_FILE_FIELDS.include?(file_field)

      mount_uploader(file_field, uploader)

      define_method("update_#{file_field}_store") do
        # The file.object_store is set during `uploader.store!` and `uploader.migrate!`
        file_field_object_store = public_send(file_field).object_store # rubocop:disable GitlabSecurity/PublicSend
        return if self["#{file_field}_store"] == file_field_object_store # update only if necessary

        update_column("#{file_field}_store", file_field_object_store)
      end

      define_method("store_#{file_field}_now!") do
        public_send("store_#{file_field}!") # rubocop:disable GitlabSecurity/PublicSend
        public_send("update_#{file_field}_store") # rubocop:disable GitlabSecurity/PublicSend
      end

      if skip_store_file
        skip_callback :save, :after, "store_#{file_field}!".to_sym

        return
      end

      # This hook is a no-op when the file is uploaded after_commit
      after_save "update_#{file_field}_store".to_sym, if: "saved_change_to_#{file_field}?".to_sym
    end
  end
end
