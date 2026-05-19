# frozen_string_literal: true

class TruncateSbomOccurrenceRefs < Gitlab::Database::Migration[2.3]
  milestone '19.0'

  # no-op: truncation moved to db/post_migrate/20260506101701_truncate_sbom_occurrence_refs_v2.rb
  def up; end

  def down; end
end
