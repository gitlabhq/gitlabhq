# frozen_string_literal: true

class ReplaceIndexSshSignaturesOnCommitSha < Gitlab::Database::Migration[2.3]
  milestone '18.7'
  disable_ddl_transaction!

  def up
    # No-op due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20989
  end

  def down
    # No-op due to https://gitlab.com/gitlab-com/gl-infra/production/-/issues/20989
  end
end
