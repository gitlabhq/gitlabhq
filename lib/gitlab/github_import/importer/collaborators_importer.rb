# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class CollaboratorsImporter
        include ParallelScheduling

        def importer_class
          CollaboratorImporter
        end

        def representation_class
          Representation::Collaborator
        end

        def sidekiq_worker_class
          ImportCollaboratorWorker
        end

        def object_type
          :collaborator
        end

        def collection_method
          :collaborators
        end

        def id_for_already_imported_cache(collaborator)
          collaborator[:id]
        end
      end
    end
  end
end
