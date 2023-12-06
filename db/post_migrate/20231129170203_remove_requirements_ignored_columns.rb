# frozen_string_literal: true

class RemoveRequirementsIgnoredColumns < Gitlab::Database::Migration[2.2]
  milestone '16.7'

  disable_ddl_transaction!

  def up
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17224
  end

  def down
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/17224
  end
end
