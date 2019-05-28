# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class WikiFormatter
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def disk_path
        project.wiki.disk_path
      end

      def full_path
        project.wiki.full_path
      end

      def import_url
        project.import_url.sub(/\.git\z/, ".wiki.git")
      end
    end
  end
end
