class MigrateBuildStageReference < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  ##
  # This is an empty migration, content has been moved to a new one:
  # post migrate 20170526190000 MigrateBuildStageReferenceAgain
  #
  # See gitlab-org/gitlab-ce!12337 for more details.

  def up
    # noop
  end

  def down
    # noop
  end
end
