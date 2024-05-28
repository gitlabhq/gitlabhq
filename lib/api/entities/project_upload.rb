# frozen_string_literal: true

module API
  module Entities
    class ProjectUpload < Grape::Entity
      include Gitlab::Routing

      expose :markdown_name, as: :alt
      expose :secure_url, as: :url
      expose :full_path do |uploader|
        if ::Feature.enabled?(:use_ids_for_markdown_upload_urls, uploader.model)
          banzai_upload_path(
            'project',
            uploader.model.id,
            uploader.secret,
            uploader.filename
          )
        else
          show_project_uploads_path(
            uploader.model,
            uploader.secret,
            uploader.filename
          )
        end
      end

      expose :markdown_link, as: :markdown
    end
  end
end
