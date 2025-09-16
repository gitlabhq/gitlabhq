# frozen_string_literal: true

module Gitlab
  module BitbucketImport
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
        project.unsafe_import_url.sub(/\.git\z/, ".git/wiki")
      end
    end
  end
end
