# frozen_string_literal: true

module Gitlab
  module ImportExport
    class SnippetRepoRestorer < RepoRestorer
      attr_reader :snippet

      def initialize(snippet:, user:, shared:, path_to_bundle:)
        @snippet = snippet
        @user = user
        @repository = snippet.repository
        @path_to_bundle = path_to_bundle.to_s
        @shared = shared
      end

      def restore
        if File.exist?(path_to_bundle)
          create_repository_from_bundle
        else
          create_repository_from_db
        end

        true
      rescue => e
        shared.error(e)
        false
      end

      private

      def create_repository_from_bundle
        repository.create_from_bundle(path_to_bundle)
        snippet.track_snippet_repository
      end

      def create_repository_from_db
        snippet.create_repository

        commit_attrs = {
          branch_name: 'master',
          message: 'Initial commit'
        }

        repository.create_file(@user, snippet.file_name, snippet.content, commit_attrs)
      end
    end
  end
end
