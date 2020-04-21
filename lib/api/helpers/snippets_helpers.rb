# frozen_string_literal: true

module API
  module Helpers
    module SnippetsHelpers
      def content_for(snippet)
        if ::Feature.enabled?(:version_snippets, current_user) && !snippet.empty_repo?
          blob = snippet.blobs.first
          blob.load_all_data!
          blob.data
        else
          snippet.content
        end
      end
    end
  end
end
