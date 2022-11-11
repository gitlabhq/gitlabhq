# frozen_string_literal: true

module API
  module Entities
    class WikiAttachment < Grape::Entity
      include Gitlab::FileMarkdownLinkBuilder

      expose :file_name, documentation: { type: 'string', example: 'dk.png' }
      expose :file_path, documentation: { type: 'string', example: 'uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png' }
      expose :branch, documentation: { type: 'string', example: 'main' }
      expose :link do
        expose :file_path, as: :url, documentation: {
          type: 'string', example: 'uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png'
        }
        expose :markdown, documentation: {
          type: 'string', example: '![dk](uploads/6a061c4cf9f1c28cb22c384b4b8d4e3c/dk.png)'
        } do |_entity|
          self.markdown_link
        end
      end

      def filename
        object[:file_name]
      end

      def secure_url
        object[:file_path]
      end
    end
  end
end
