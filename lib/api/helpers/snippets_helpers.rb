# frozen_string_literal: true

module API
  module Helpers
    module SnippetsHelpers
      def content_for(snippet)
        if snippet.empty_repo?
          snippet.content
        else
          blob = snippet.blobs.first
          blob.load_all_data!
          blob.data
        end
      end
    end
  end
end
