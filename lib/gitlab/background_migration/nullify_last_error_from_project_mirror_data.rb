# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Nullifies last_error value from project_mirror_data table as they
    # potentially included sensitive data.
    # https://gitlab.com/gitlab-org/security/gitlab/-/merge_requests/3041
    class NullifyLastErrorFromProjectMirrorData < BatchedMigrationJob
      feature_category :source_code_management
      operation_name :update_all

      def perform
        each_sub_batch { |rel| rel.update_all(last_error: nil) }
      end
    end
  end
end
