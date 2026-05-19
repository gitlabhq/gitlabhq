# frozen_string_literal: true

module API
  module Entities
    class Snippet < BasicSnippet
      expose :author, using: ::API::Entities::UserBasic, documentation: { type: '::API::Entities::UserBasic' }
      expose :file_name, documentation: { type: 'String', example: 'add.rb' } do |snippet|
        snippet_files.first || snippet.file_name
      end
      expose :files, documentation: {
        type: 'Hash',
        is_array: true, example: [{
          path: 'file.txt',
          raw_url: 'https://gitlab.example.com/.../raw'
        }]
      } do |snippet, options|
        snippet_files.map do |file|
          {
            path: file,
            raw_url: Gitlab::UrlBuilder.build(snippet, file: file, ref: snippet.repository.root_ref)
          }
        end
      end
      expose :imported?, as: :imported, documentation: { type: 'Boolean', example: false }
      expose :imported_from, documentation: { type: 'String', example: 'none' }

      private

      def snippet_files
        @snippet_files ||= object.list_files
      end
    end
  end
end

API::Entities::Snippet.prepend_mod_with('API::Entities::Snippet', with_descendants: true)
