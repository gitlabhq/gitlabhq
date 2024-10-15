# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillCiSecureFileStatesProjectId < BackfillDesiredShardingKeyJob
      operation_name :backfill_ci_secure_file_states_project_id
      feature_category :secrets_management
    end
  end
end
