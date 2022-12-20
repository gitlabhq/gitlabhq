# frozen_string_literal: true

module Import
  module GitlabProjects
    module FileAcquisitionStrategies
      class FileUpload
        include ActiveModel::Validations

        validate :uploaded_file

        def initialize(params:, current_user: nil)
          @params = params
        end

        def project_params
          @project_params ||= @params.slice(:file)
        end

        def file
          @file ||= @params[:file]
        end

        private

        def uploaded_file
          return if file.present? && file.is_a?(UploadedFile)

          errors.add(:file, 'must be uploaded')
        end
      end
    end
  end
end
