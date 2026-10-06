# frozen_string_literal: true

class AddReachabilityToSbomOccurrenceRefs < Gitlab::Database::Migration[2.3]
  milestone '19.5'

  def change
    # NULL means not written for this ref yet, so reads can fall back to sbom_occurrences.reachability
    add_column :sbom_occurrence_refs, :reachability, :smallint
  end
end
