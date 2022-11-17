# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class ProtectedBranchesImporter
        include ParallelScheduling

        # The method that will be called for traversing through all the objects to
        # import, yielding them to the supplied block.
        def each_object_to_import
          repo = project.import_source

          protected_branches = client.branches(repo).select { |branch| branch.dig(:protection, :enabled) }
          protected_branches.each do |protected_branch|
            next if already_imported?(protected_branch)

            object = client.branch_protection(repo, protected_branch[:name])
            next if object.nil?

            yield object

            Gitlab::GithubImport::ObjectCounter.increment(project, object_type, :fetched)
            mark_as_imported(protected_branch)
          end
        end

        def importer_class
          ProtectedBranchImporter
        end

        def representation_class
          Gitlab::GithubImport::Representation::ProtectedBranch
        end

        def sidekiq_worker_class
          ImportProtectedBranchWorker
        end

        def object_type
          :protected_branch
        end

        def collection_method
          :protected_branches
        end

        def id_for_already_imported_cache(protected_branch)
          protected_branch[:name]
        end
      end
    end
  end
end
