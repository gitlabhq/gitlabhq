# frozen_string_literal: true

module Gitlab
  module ImportExport
    class SnippetsRepoSaver
      include Gitlab::ImportExport::CommandLineUtil
      include DurationMeasuring

      def initialize(current_user:, project:, shared:)
        @project = project
        @shared = shared
        @current_user = current_user
      end

      def save
        with_duration_measuring do
          create_snippets_repo_directory

          @project.snippets.find_each.all? do |snippet|
            Gitlab::ImportExport::SnippetRepoSaver.new(project: @project,
              shared: @shared,
              repository: snippet.repository)
                                                  .save
          end
        end
      end

      private

      def create_snippets_repo_directory
        mkdir_p(::Gitlab::ImportExport.snippets_repo_bundle_path(@shared.export_path))
      end
    end
  end
end
