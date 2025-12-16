# frozen_string_literal: true

# rubocop:disable Migration/BatchedMigrationBaseClass -- it is a subclass of Gitlab::BackgroundMigration::BatchedMigrationJob
module Gitlab
  module BackgroundMigration
    class MoveCiBuildsMetadataSelfManaged < MoveCiBuildsMetadata
      feature_category :continuous_integration
      operation_name :create_job_definition_from_builds_metadata
    end
  end
end
# rubocop:enable Migration/BatchedMigrationBaseClass
