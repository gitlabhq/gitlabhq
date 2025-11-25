# frozen_string_literal: true

class TrackSlsaAttestationDeletions < Gitlab::Database::Migration[2.3]
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  milestone '18.7'

  def up
    track_record_deletions(:slsa_attestations)
  end

  def down
    untrack_record_deletions(:slsa_attestations)
  end
end
