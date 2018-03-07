# frozen_string_literal: true

module Gitlab
  module GithubImport
    # The SequentialImporter imports a GitHub project in a single thread,
    # without using Sidekiq. This makes it useful for testing purposes as well
    # as Rake tasks, but it should be avoided for anything else in favour of the
    # parallel importer.
    class SequentialImporter
      attr_reader :project, :client

      SEQUENTIAL_IMPORTERS = [
        Importer::LabelsImporter,
        Importer::MilestonesImporter,
        Importer::ReleasesImporter
      ].freeze

      PARALLEL_IMPORTERS = [
        Importer::PullRequestsImporter,
        Importer::IssuesImporter,
        Importer::DiffNotesImporter,
        Importer::NotesImporter
      ].freeze

      # project - The project to import the data into.
      # token - The token to use for the GitHub API.
      def initialize(project, token: nil)
        @project = project
        @client = GithubImport
          .new_client_for(project, token: token, parallel: false)
      end

      def execute
        Importer::RepositoryImporter.new(project, client).execute

        SEQUENTIAL_IMPORTERS.each do |klass|
          klass.new(project, client).execute
        end

        PARALLEL_IMPORTERS.each do |klass|
          klass.new(project, client, parallel: false).execute
        end

        project.repository.after_import

        true
      end
    end
  end
end
