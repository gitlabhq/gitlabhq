# frozen_string_literal: true

Gitlab::Seeder.quiet do
  Gitlab::DatabaseImporters::ProgrammingLanguagesImporter.import
end
