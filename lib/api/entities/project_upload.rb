# frozen_string_literal: true

module API
  module Entities
    class ProjectUpload < Grape::Entity
      include Gitlab::Routing

      expose :markdown_name, as: :alt
      expose :secure_url, as: :url
      expose :full_path do |uploader|
        show_project_uploads_path(
          uploader.model,
          uploader.secret,
          uploader.filename
        )
      end

      expose :markdown_link, as: :markdown
    end
  end
end
