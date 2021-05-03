# frozen_string_literal: true

module Gitlab
  module LocalAndRemoteStorageMigration
    class ArtifactMigrater < Gitlab::LocalAndRemoteStorageMigration::BaseMigrater
      private

      def items_with_files_stored_locally
        ::Ci::JobArtifact.with_files_stored_locally
      end

      def items_with_files_stored_remotely
        ::Ci::JobArtifact.with_files_stored_remotely
      end
    end
  end
end
