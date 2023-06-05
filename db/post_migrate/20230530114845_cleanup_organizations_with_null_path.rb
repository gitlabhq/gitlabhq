# frozen_string_literal: true

class CleanupOrganizationsWithNullPath < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  module Organizations
    class Organization < Gitlab::Database::Migration[2.1]::MigrationRecord
    end
  end

  def up
    Organizations::Organization.update_all("path = lower(name)")
  end

  def down
    Organizations::Organization.update_all(path: '')
  end
end
