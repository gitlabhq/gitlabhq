# frozen_string_literal: true

class RemoveFaultyAsyncIndexDefinitions2 < Gitlab::Database::Migration[2.2]
  milestone '17.6'

  def up
    unprepare_async_index_by_name 'gitlab_partitions_dynamic.security_findings_126', 'index_ee8a554af9'
  end

  def down
    # no-op
  end
end
