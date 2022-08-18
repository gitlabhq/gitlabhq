# frozen_string_literal: true

module Import
  class PrepareService < ::BaseService
    def execute
      uploader = UploadService.new(project, params[:file]).execute

      if uploader
        enqueue_import(uploader.upload)

        ServiceResponse.success(message: success_message)
      else
        ServiceResponse.error(message: _('File upload error.'))
      end
    end

    private

    def enqueue_import(upload)
      worker.perform_async(current_user.id, project.id, upload.id)
    end

    def worker
      raise NotImplementedError
    end

    def success_message
      raise NotImplementedError
    end
  end
end
