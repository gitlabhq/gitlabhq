# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportCollaboratorWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      def representation_class
        Representation::Collaborator
      end

      def importer_class
        Importer::CollaboratorImporter
      end

      def object_type
        :collaborator
      end
    end
  end
end
