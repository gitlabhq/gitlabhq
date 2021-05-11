# frozen_string_literal: true

module API
  module Helpers
    module SearchHelpers
      def self.global_search_scopes
        # This is a separate method so that EE can redefine it.
        %w(projects issues merge_requests milestones snippet_titles users)
      end

      def self.group_search_scopes
        # This is a separate method so that EE can redefine it.
        %w(projects issues merge_requests milestones users)
      end

      def self.project_search_scopes
        # This is a separate method so that EE can redefine it.
        %w(issues merge_requests milestones notes wiki_blobs commits blobs users)
      end

      def self.search_states
        %w(all opened closed merged)
      end
    end
  end
end

API::Helpers::SearchHelpers.prepend_mod_with('API::Helpers::SearchHelpers')
