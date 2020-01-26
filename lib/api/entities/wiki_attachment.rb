# frozen_string_literal: true

module API
  module Entities
    class WikiAttachment < Grape::Entity
      include Gitlab::FileMarkdownLinkBuilder

      expose :file_name
      expose :file_path
      expose :branch
      expose :link do
        expose :file_path, as: :url
        expose :markdown do |_entity|
          self.markdown_link
        end
      end

      def filename
        object.file_name
      end

      def secure_url
        object.file_path
      end
    end
  end
end
