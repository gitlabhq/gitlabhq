# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class SetUploadsPathSizeForMysql < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  def up
    # We need at least 297 at the moment. For more detail on that number, see:
    # https://gitlab.com/gitlab-org/gitlab-ce/issues/40168#what-is-the-expected-correct-behavior
    #
    # Rails + PostgreSQL `string` is equivalent to a `text` field, but
    # Rails + MySQL `string` is `varchar(255)` by default. Also, note that we
    # have an upper limit because with a unique index, MySQL has a max key
    # length of 3072 bytes which seems to correspond to `varchar(1024)`.
    change_column :uploads, :path, :string, limit: 511
  end

  def down
    # It was unspecified, which is varchar(255) by default in Rails for MySQL.
    change_column :uploads, :path, :string
  end
end
