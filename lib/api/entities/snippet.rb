# frozen_string_literal: true

module API
  module Entities
    class Snippet < BasicSnippet
      expose :author, using: Entities::UserBasic
      expose :file_name do |snippet|
        snippet_files.first || snippet.file_name
      end
      expose :files do |snippet, options|
        snippet_files.map do |file|
          {
            path: file,
            raw_url: Gitlab::UrlBuilder.build(snippet, file: file, ref: snippet.repository.root_ref)
          }
        end
      end

      private

      def snippet_files
        @snippet_files ||= object.list_files
      end
    end
  end
end
