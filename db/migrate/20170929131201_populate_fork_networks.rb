# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class PopulateForkNetworks < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    say 'Fork networks will be populated in 20171205190711 - RescheduleForkNetworkCreationCaller'
  end

  def down
    # nothing
  end
end
