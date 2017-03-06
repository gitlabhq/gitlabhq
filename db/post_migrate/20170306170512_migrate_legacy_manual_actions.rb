class MigrateLegacyManualActions < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    execute <<-EOS
      UPDATE ci_builds SET status = 'manual', allow_failure = true
        WHERE ci_builds.when = 'manual' AND ci_builds.status = 'skipped';
    EOS
  end

  def down
    execute <<-EOS
      UPDATE ci_builds SET status = 'skipped', allow_failure = false
        WHERE ci_builds.when = 'manual' AND ci_builds.status = 'manual';
    EOS
  end
end
