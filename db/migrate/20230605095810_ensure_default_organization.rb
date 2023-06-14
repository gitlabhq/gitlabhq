# frozen_string_literal: true

class EnsureDefaultOrganization < Gitlab::Database::Migration[2.1]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  disable_ddl_transaction!

  class Organization < MigrationRecord
  end

  def up
    return if Organization.exists?(id: 1)

    path = 'default'

    retries = 0

    begin
      Organization.create(id: 1, name: 'Default', path: path)
    rescue ActiveRecord::RecordNotUnique
      retries += 1
      path = "default-#{SecureRandom.hex(3)}"
      retry if retries < 10_000
    end
  end

  def down
    Organization.where(id: 1).delete_all
  end
end
