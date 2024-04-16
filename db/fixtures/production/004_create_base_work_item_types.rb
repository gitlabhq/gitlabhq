# frozen_string_literal: true

Gitlab::Seeder.quiet do
  Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.upsert_types
end
