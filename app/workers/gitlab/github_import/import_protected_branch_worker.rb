# frozen_string_literal: true

module Gitlab
  module GithubImport
    class ImportProtectedBranchWorker # rubocop:disable Scalability/IdempotentWorker
      include ObjectImporter

      worker_resource_boundary :cpu

      def representation_class
        Gitlab::GithubImport::Representation::ProtectedBranch
      end

      def importer_class
        Importer::ProtectedBranchImporter
      end

      def object_type
        :protected_branch
      end
    end
  end
end
