# frozen_string_literal: true

module Gitlab
  module ImportExport
    class SnippetsRepoRestorer
      def initialize(project:, shared:, user:)
        @project = project
        @shared = shared
        @user = user
      end

      def restore
        @project.snippets.find_each.map do |snippet|
          Gitlab::ImportExport::SnippetRepoRestorer.new(snippet: snippet,
            user: @user,
            shared: @shared,
            path_to_bundle: snippet_repo_bundle_path(snippet))
                                                   .restore
        end.all?(true)
      end

      private

      def snippet_repo_bundle_path(snippet)
        File.join(snippets_repo_bundle_path, ::Gitlab::ImportExport.snippet_repo_bundle_filename_for(snippet))
      end

      def snippets_repo_bundle_path
        @snippets_repo_bundle_path ||= ::Gitlab::ImportExport.snippets_repo_bundle_path(@shared.export_path)
      end
    end
  end
end
