# frozen_string_literal: true

class ValidateNotNullShardingKeyOnSecurityFindings < Gitlab::Database::Migration[2.3]
  milestone '18.10'

  # validated asynchronously on gitlab.com in
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/221339
  def up
    validate_not_null_constraint :security_findings, :project_id
  end

  def down; end
end
