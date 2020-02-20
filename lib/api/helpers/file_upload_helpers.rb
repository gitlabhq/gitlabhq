# frozen_string_literal: true

module API
  module Helpers
    module FileUploadHelpers
      def file_is_valid?
        params[:file] && params[:file]['tempfile'].respond_to?(:read)
      end

      def validate_file!
        render_api_error!('Uploaded file is invalid', 400) unless file_is_valid?
      end
    end
  end
end
