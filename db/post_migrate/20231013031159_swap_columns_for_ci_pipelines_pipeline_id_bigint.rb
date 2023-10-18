# frozen_string_literal: true

class SwapColumnsForCiPipelinesPipelineIdBigint < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16998
  end

  def down
    # no-op to mitigate https://gitlab.com/gitlab-com/gl-infra/production/-/issues/16998
  end
end
