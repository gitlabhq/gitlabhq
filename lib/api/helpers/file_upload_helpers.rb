# frozen_string_literal: true

module API
  module Helpers
    module FileUploadHelpers
      def file_is_valid?
        filename = params[:file]&.original_filename
        filename && ImportExportUploader::EXTENSION_ALLOWLIST.include?(File.extname(filename).delete('.'))
      end

      def validate_file!
        render_api_error!({ error: _('You need to upload a GitLab project export archive (ending in .gz).') }, 422) unless file_is_valid?
      end
    end
  end
end
