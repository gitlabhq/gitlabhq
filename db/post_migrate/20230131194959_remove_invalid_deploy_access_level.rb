# frozen_string_literal: true

class RemoveInvalidDeployAccessLevel < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    # no-op, moved to 20230322151605_rerun_remove_invalid_deploy_access_level.rb
  end

  def down
    # no-op
  end
end
