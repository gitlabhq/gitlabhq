# frozen_string_literal: true

module API
  module Entities
    class Snippet < BasicSnippet
      expose :author, using: Entities::UserBasic, documentation: { type: 'Entities::UserBasic' }
      expose :file_name, documentation: { type: 'string', example: 'add.rb' } do |snippet|
        snippet_files.first || snippet.file_name
      end
      expose :files, documentation: {
        is_array: true, example: 'e0d123e5f316bef78bfdf5a008837577'
      } do |snippet, options|
        snippet_files.map do |file|
          {
            path: file,
            raw_url: Gitlab::UrlBuilder.build(snippet, file: file, ref: snippet.repository.root_ref)
          }
        end
      end
      expose :imported?, as: :imported, documentation: { type: 'boolean', example: false }
      expose :imported_from, documentation: { type: 'string', example: 'none' }

      private

      def snippet_files
        @snippet_files ||= object.list_files
      end
    end
  end
end

API::Entities::Snippet.prepend_mod_with('API::Entities::Snippet', with_descendants: true)
