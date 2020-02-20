# frozen_string_literal: true

class ScheduleLinkLfsObjects < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    # no-op as background migration being schedule times out in some instances
  end

  def down
    # no-op
  end
end
