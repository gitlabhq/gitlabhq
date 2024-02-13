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

      def self.track_start_import(project)
        Gitlab::Import::Metrics.new(:github_importer, project).track_start_import
      end

      # This is a workaround for a Ruby 2.3.7 bug. rspec-mocks cannot restore
      # the visibility of prepended modules. See
      # https://github.com/rspec/rspec-mocks/issues/1231 for more details.
      if Rails.env.test?
        def self.requires_ci_cd_setup?
          raise NotImplementedError
        end
      end

      def initialize(project)
        @project = project
      end

      def execute
        Gitlab::Import::SetAsyncJid.set_jid(project.import_state)

        # We need to track this job's status for use by Gitlab::Import::RefreshImportJidWorker.
        Stage::ImportRepositoryWorker
          .with_status
          .perform_async(project.id)

        true
      end
    end
  end
end

Gitlab::GithubImport::ParallelImporter.prepend_mod_with('Gitlab::GithubImport::ParallelImporter')
