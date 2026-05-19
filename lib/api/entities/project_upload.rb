# frozen_string_literal: true

module API
  module Entities
    class ProjectUpload < Grape::Entity
      include Gitlab::Routing

      expose :id, documentation: { type: 'Integer', example: 1 } do |uploader|
        uploader.upload.id
      end
      expose :markdown_name, as: :alt, documentation: { type: 'String', example: 'filename' }
      expose :secure_url, as: :url, documentation: { type: 'String', example: '/uploads/secret/filename' }
      expose :full_path,
        documentation: { type: 'String', example: '/-/project/1/uploads/secret/filename' } do |uploader|
        banzai_upload_path(
          'project',
          uploader.model.id,
          uploader.secret,
          uploader.filename
        )
      end

      expose :markdown_link, as: :markdown,
        documentation: { type: 'String', example: '[filename](/uploads/secret/filename)' }
    end
  end
end
