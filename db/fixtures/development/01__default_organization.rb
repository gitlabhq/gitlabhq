# frozen_string_literal: true

Gitlab::Seeder.quiet do
  Gitlab::DatabaseImporters::DefaultOrganizationImporter.create_default_organization
end
