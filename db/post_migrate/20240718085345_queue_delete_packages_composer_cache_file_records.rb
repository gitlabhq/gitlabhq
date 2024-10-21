# frozen_string_literal: true

class QueueDeletePackagesComposerCacheFileRecords < Gitlab::Database::Migration[2.2]
  milestone '17.3'

  # The migration was finalized in 17.4
  # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159861#note_2067062639
  def up
    # no-op
  end

  def down
    # no-op
  end
end
