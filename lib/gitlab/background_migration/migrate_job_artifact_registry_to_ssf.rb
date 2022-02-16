# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # rubocop: disable Style/Documentation
    class MigrateJobArtifactRegistryToSsf
      def perform(*job_artifact_ids)
      end
    end
  end
end

Gitlab::BackgroundMigration::MigrateJobArtifactRegistryToSsf.prepend_mod_with('Gitlab::BackgroundMigration::MigrateJobArtifactRegistryToSsf')
