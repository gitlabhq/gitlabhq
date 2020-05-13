# frozen_string_literal: true

class BackfillEnvironmentIdOnDeploymentMergeRequests < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # no-op

    # this migration is deleted because there is no foreign key for
    # deployments.environment_id and this caused a failure upgrading
    # deployments_merge_requests.environment_id
    #
    # Details on the following issues:
    #  * https://gitlab.com/gitlab-org/gitlab/-/issues/217191
    #  * https://gitlab.com/gitlab-org/gitlab/-/issues/26229
  end

  def down
    # no-op

    # this migration is designed to delete duplicated data
  end
end
