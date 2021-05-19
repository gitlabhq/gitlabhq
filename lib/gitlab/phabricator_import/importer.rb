# frozen_string_literal: true

module Gitlab
  module PhabricatorImport
    class Importer
      def self.async?
        true
      end

      def self.imports_repository?
        # This does not really import a repository, but we want to skip all
        # repository related tasks in the `Projects::ImportService`
        true
      end

      def initialize(project)
        @project = project
      end

      def execute
        Gitlab::Import::SetAsyncJid.set_jid(project.import_state)
        schedule_first_tasks_page

        true
      rescue StandardError => e
        fail_import(e.message)

        false
      end

      private

      attr_reader :project

      def schedule_first_tasks_page
        ImportTasksWorker.schedule(project.id)
      end

      def fail_import(message)
        project.import_state.mark_as_failed(message)
      end
    end
  end
end
