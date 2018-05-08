# frozen_string_literal: true

module Gitlab
  module GithubImport
    # The ParallelImporter schedules the importing of a GitHub project using
    # Sidekiq.
    class ParallelImporter
      attr_reader :project

      def self.async?
        true
      end

      def self.imports_repository?
        true
      end

      def initialize(project)
        @project = project
      end

      def execute
        jid = generate_jid

        # The original import JID is the JID of the RepositoryImportWorker job,
        # which will be removed once that job completes. Reusing that JID could
        # result in StuckImportJobsWorker marking the job as stuck before we get
        # to running Stage::ImportRepositoryWorker.
        #
        # We work around this by setting the JID to a custom generated one, then
        # refreshing it in the various stages whenever necessary.
        Gitlab::SidekiqStatus
          .set(jid, StuckImportJobsWorker::IMPORT_JOBS_EXPIRATION)

        project.update_column(:import_jid, jid)

        Stage::ImportRepositoryWorker
          .perform_async(project.id)

        true
      end

      def generate_jid
        "github-importer/#{project.id}"
      end
    end
  end
end
