# frozen_string_literal: true

module API
  module Entities
    class MarkdownUploadAdmin < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :size, documentation: { type: 'Integer', example: 1024 }
      expose :filename, documentation: { type: 'String', example: 'image.png' }
      expose :created_at, documentation: { type: 'DateTime', example: '2012-06-28T10:52:04Z' }
      expose :uploaded_by_user, as: :uploaded_by, using: ::API::Entities::UserSafe,
        documentation: { type: '::API::Entities::UserSafe' }
    end
  end
end
