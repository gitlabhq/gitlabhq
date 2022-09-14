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
        Importer::ProtectedBranchesImporter,
        Importer::PullRequestsImporter,
        Importer::IssuesImporter,
        Importer::DiffNotesImporter,
        Importer::NotesImporter,
        Importer::LfsObjectsImporter
      ].freeze

      # project - The project to import the data into.
      # token - The token to use for the GitHub API.
      # host - The GitHub hostname. If nil, github.com will be used.
      def initialize(project, token: nil, host: nil)
        @project = project
        @client = GithubImport
          .new_client_for(project, token: token, host: host, parallel: false)
      end

      def execute
        metrics.track_start_import

        begin
          Importer::RepositoryImporter.new(project, client).execute

          SEQUENTIAL_IMPORTERS.each do |klass|
            klass.new(project, client).execute
          end

        rescue StandardError => e
          Gitlab::Import::ImportFailureService.track(
            project_id: project.id,
            error_source: self.class.name,
            exception: e,
            fail_import: true,
            metrics: true
          )

          raise(e)
        end

        PARALLEL_IMPORTERS.each do |klass|
          klass.new(project, client, parallel: false).execute
        end

        metrics.track_finished_import

        true
      end

      private

      def metrics
        @metrics ||= Gitlab::Import::Metrics.new(:github_importer, project)
      end
    end
  end
end
