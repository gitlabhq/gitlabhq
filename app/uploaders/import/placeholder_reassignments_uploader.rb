# frozen_string_literal: true

module Import
  class PlaceholderReassignmentsUploader < AttachmentUploader
    class << self
      def workhorse_local_upload_path
        File.join(options.storage_path, 'uploads', ObjectStorage::TMP_UPLOAD_PATH)
      end
    end

    def mounted_as
      super || 'placeholder_reassignment_csv'
    end

    private

    def dynamic_segment
      File.join(model.class.underscore, model.id.to_s, mounted_as.to_s)
    end
  end
end
