# frozen_string_literal: true

class UpdateTupleStatsForMetadataMigrations < Gitlab::Database::Migration[2.3]
  milestone '18.7'

  # No-op because it was fixed in https://gitlab.com/gitlab-org/gitlab/-/merge_requests/214040
  def up; end

  def down; end
end
