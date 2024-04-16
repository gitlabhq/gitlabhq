# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportIssueEventWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Representation::IssueEvent
      end

      def importer_class
        Importer::IssueEventImporter
      end

      def object_type
        :issue_event
      end

      def increment_object_counter(object, project)
        counter_type = importer_class::EVENT_COUNTER_MAP[object[:event]] || object_type
        Gitlab::GithubImport::ObjectCounter.increment(project, counter_type, :imported)
      end

      def import_settings
        @import_settings ||= Gitlab::GithubImport::Settings.new(project)
      end
    end
  end
end
