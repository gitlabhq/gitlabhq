# frozen_string_literal: true

Gitlab::Seeder.quiet do
  Gitlab::DatabaseImporters::WorkItems::RelatedLinksRestrictionsImporter.upsert_restrictions
end
