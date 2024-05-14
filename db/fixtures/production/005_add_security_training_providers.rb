# frozen_string_literal: true

Gitlab::Seeder.quiet do
  ::Gitlab::DatabaseImporters::Security::TrainingProviders::Importer.upsert_providers
end
