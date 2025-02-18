# frozen_string_literal: true

class PrepareNotNullOnVulnerabilitiesDetectedAtValidation < Gitlab::Database::Migration[2.2]
  milestone '17.9'

  def change
    # reverted due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/19236
  end
end
