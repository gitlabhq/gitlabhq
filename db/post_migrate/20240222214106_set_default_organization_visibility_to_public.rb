# frozen_string_literal: true

class SetDefaultOrganizationVisibilityToPublic < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '16.10'

  class Organization < MigrationRecord
    self.table_name = 'organizations'
  end

  DEFAULT_ORGANIZATION_ID = 1
  PUBLIC_VISIBILITY = 20
  PRIVATE_VISIBILITY = 0

  def up
    default_organization = Organization.find_by_id(DEFAULT_ORGANIZATION_ID)

    return unless default_organization

    default_organization.update_column(:visibility_level, PUBLIC_VISIBILITY)
  end

  def down
    default_organization = Organization.find_by_id(DEFAULT_ORGANIZATION_ID)

    return unless default_organization

    default_organization.update_column(:visibility_level, PRIVATE_VISIBILITY)
  end
end
