class RescheduleForkNetworkCreation < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    say 'Fork networks will be populated in 20171205190711 - RescheduleForkNetworkCreationCaller'
  end

  def down
    # nothing
  end
end
