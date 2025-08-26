# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDeploymentMergeRequestsForBigintConversion < CopyColumnUsingBackgroundMigrationJob
      cursor :deployment_id, :merge_request_id
    end
  end
end
