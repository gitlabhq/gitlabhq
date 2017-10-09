class MigrateLegacyManualActions < ActiveRecord::Migration[4.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    disable_statement_timeout

    execute <<-EOS
      UPDATE ci_builds SET status = 'manual', allow_failure = true
        WHERE ci_builds.when = 'manual' AND ci_builds.status = 'skipped';
    EOS
  end

  def down
    disable_statement_timeout

    execute <<-EOS
      UPDATE ci_builds SET status = 'skipped', allow_failure = false
        WHERE ci_builds.when = 'manual' AND ci_builds.status = 'manual';
    EOS
  end
end
