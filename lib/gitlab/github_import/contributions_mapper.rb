# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ContributionsMapper
      def initialize(project)
        @project = project
      end

      def user_mapper
        ::Gitlab::Import::SourceUserMapper.new(
          namespace: project.root_ancestor,
          source_hostname: project.import_url,
          import_type: ::Import::SOURCE_GITHUB
        )
      end

      def user_mapping_enabled?
        Gitlab::GithubImport::Settings.new(project).user_mapping_enabled?
      end

      private

      attr_reader :project
    end
  end
end
