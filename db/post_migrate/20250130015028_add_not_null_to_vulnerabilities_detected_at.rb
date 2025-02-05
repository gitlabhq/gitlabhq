# frozen_string_literal: true

class AddNotNullToVulnerabilitiesDetectedAt < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!

  milestone '17.9'

  def change
    # reverted due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19236
  end
end
