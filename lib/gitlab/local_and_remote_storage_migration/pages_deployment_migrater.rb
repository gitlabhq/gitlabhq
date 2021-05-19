# frozen_string_literal: true

module Gitlab
  module LocalAndRemoteStorageMigration
    class PagesDeploymentMigrater < Gitlab::LocalAndRemoteStorageMigration::BaseMigrater
      private

      def items_with_files_stored_locally
        ::PagesDeployment.with_files_stored_locally
      end

      def items_with_files_stored_remotely
        ::PagesDeployment.with_files_stored_remotely
      end
    end
  end
end
