class AddStageIdIndexToBuilds < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  ##
  # Improved in 20170703102400_add_stage_id_foreign_key_to_builds.rb
  #

  def up
    # noop
  end

  def down
    # noop
  end
end
