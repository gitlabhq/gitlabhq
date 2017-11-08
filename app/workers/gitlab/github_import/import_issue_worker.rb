# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportIssueWorker
      include ObjectImporter

      def representation_class
        Representation::Issue
      end

      def importer_class
        Importer::IssueAndLabelLinksImporter
      end

      def counter_name
        :github_importer_imported_issues
      end

      def counter_description
        'The number of imported GitHub issues'
      end
    end
  end
end
