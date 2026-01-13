# frozen_string_literal: true

class QueueDeleteOrphanedRelationExportUploads < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  # re-enqueued via https://gitlab.com/gitlab-org/gitlab/-/merge_requests/218125
  def up; end

  def down; end
end
