# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class CollaboratorsImporter
        include ParallelScheduling

        # The method that will be called for traversing through all the objects to
        # import, yielding them to the supplied block.
        def each_object_to_import
          repo = project.import_source

          direct_collaborators = client.collaborators(repo, affiliation: 'direct')
          outside_collaborators = client.collaborators(repo, affiliation: 'outside')
          collaborators_to_import = direct_collaborators.to_a - outside_collaborators.to_a

          collaborators_to_import.each do |collaborator|
            next if already_imported?(collaborator)

            yield collaborator

            Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)
            mark_as_imported(collaborator)
          end
        end

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
