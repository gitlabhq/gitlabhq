module Gitlab
  module GithubImport
    class WikiFormatter
      attr_reader :project

      def initialize(project)
        @project = project
      end

      def path_with_namespace
        "#{project.path_with_namespace}.wiki"
      end

      def import_url
        project.import_url.sub(/\.git\z/, ".wiki.git")
      end
    end
  end
end
