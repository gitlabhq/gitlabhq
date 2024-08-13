# frozen_string_literal: true

module API
  module Entities
    class ProjectUpload < Grape::Entity
      include Gitlab::Routing

      expose :id do |uploader|
        uploader.upload.id
      end
      expose :markdown_name, as: :alt
      expose :secure_url, as: :url
      expose :full_path do |uploader|
        banzai_upload_path(
          'project',
          uploader.model.id,
          uploader.secret,
          uploader.filename
        )
      end

      expose :markdown_link, as: :markdown
    end
  end
end
