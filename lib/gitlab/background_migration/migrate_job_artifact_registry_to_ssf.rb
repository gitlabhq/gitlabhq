# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class MigrateJobArtifactRegistryToSsf
      def perform(*job_artifact_ids); end
    end
  end
end

Gitlab::BackgroundMigration::MigrateJobArtifactRegistryToSsf.prepend_mod_with('Gitlab::BackgroundMigration::MigrateJobArtifactRegistryToSsf')
