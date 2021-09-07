# frozen_string_literal: true

Gitlab::Seeder.quiet do
  Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.import
end
