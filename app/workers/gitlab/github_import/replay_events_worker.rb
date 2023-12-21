# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ReplayEventsWorker
      include ObjectImporter

      idempotent!

      def representation_class
        Representation::ReplayEvent
      end

      def importer_class
        Importer::ReplayEventsImporter
      end

      def object_type
        :replay_event
      end

      def increment_object_counter?(_object)
        false
      end
    end
  end
end
