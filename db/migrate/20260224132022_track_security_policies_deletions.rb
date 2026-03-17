# frozen_string_literal: true

class TrackSecurityPoliciesDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.10'

  def up
    track_record_deletions(:security_policies)
  end

  def down
    untrack_record_deletions(:security_policies)
  end
end
