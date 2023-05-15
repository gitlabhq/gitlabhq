# frozen_string_literal: true

class AddDefaultOrganization < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class Organization < MigrationRecord
  end

  def up
    Organization.create(id: 1, name: 'Default')
  end

  def down
    Organization.where(id: 1).delete_all
  end
end
