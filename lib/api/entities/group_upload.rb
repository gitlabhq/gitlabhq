# frozen_string_literal: true

module API
  module Entities
    class GroupUpload < Grape::Entity
      include Gitlab::Routing

      expose :id, documentation: { type: 'Integer', desc: 'The ID of the file' } do |uploader|
        uploader.upload.id
      end

      expose :markdown_name, as: :alt, documentation: { type: 'String', desc: 'The name of the file' }
      expose :secure_url, as: :url, documentation: { type: 'String', desc: 'The URL to access the file' }

      expose :full_path, documentation: { type: 'String', desc: 'The full path to the file' } do |uploader|
        banzai_upload_path(
          'group',
          uploader.model.id,
          uploader.secret,
          uploader.filename
        )
      end

      expose :markdown_link, as: :markdown,
        documentation: { type: 'String', desc: 'A markdown-formatted link to the file.' }
    end
  end
end
