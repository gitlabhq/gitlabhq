# frozen_string_literal: true

module API
  module Entities
    class Snippet < BasicSnippet
      expose :author, using: Entities::UserBasic
      expose :file_name do |snippet|
        snippet.file_name_on_repo || snippet.file_name
      end
      expose :files do |snippet, options|
        snippet.list_files.map do |file|
          {
            path: file,
            raw_url: Gitlab::UrlBuilder.build(snippet, file: file, ref: snippet.repository.root_ref)
          }
        end
      end
    end
  end
end
