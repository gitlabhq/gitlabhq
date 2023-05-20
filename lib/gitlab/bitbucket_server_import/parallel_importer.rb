# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    class ParallelImporter
      def self.async?
        true
      end

      def self.imports_repository?
        true
      end

      def self.track_start_import(project)
        Gitlab::Import::Metrics.new(:bitbucket_server_importer, project).track_start_import
      end

      def initialize(project)
        @project = project
      end

      def execute
        Gitlab::Import::SetAsyncJid.set_jid(project.import_state)

        Stage::ImportRepositoryWorker
          .with_status
          .perform_async(project.id)

        true
      end

      private

      attr_reader :project
    end
  end
end
