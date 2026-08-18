# frozen_string_literal: true

module API
  module Entities
    class BatchBlob < Grape::Entity
      expose :path, documentation: { type: 'String', example: 'app/models/user.rb' }
      expose :commit_id, as: :ref, documentation: { type: 'String', example: 'main' }
      expose :size, documentation: { type: 'Integer', example: 1476 }
      expose :truncated?, as: :truncated, documentation: { type: 'Boolean', example: false }
      expose :encoding, documentation: { type: 'String', example: 'base64' }
      expose :content, documentation: { type: 'String', example: 'VGhpcyBpcyBhIGZpbGU=' }

      private

      def encoding
        'base64'
      end

      def content
        Base64.strict_encode64(object.data)
      end
    end
  end
end
