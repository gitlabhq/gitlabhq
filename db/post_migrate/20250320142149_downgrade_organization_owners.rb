# frozen_string_literal: true

class DowngradeOrganizationOwners < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main
  milestone '17.11'

  class User < MigrationRecord
    self.table_name = :users

    has_many :organization_users
  end

  class OrganizationUser < MigrationRecord
    self.table_name = :organization_users

    belongs_to :user
  end

  # rubocop:disable Rails/FindEach -- Find Each is adding an order by id which makes this slow. Number of records is small.
  def up
    OrganizationUser.where(access_level: 50).each do |organization_user|
      organization_user.update!(access_level: 10) unless organization_user.user.admin? # rubocop:disable Cop/UserAdmin -- Application logic is not available here
    end
  end
  # rubocop:enable Rails/FindEach

  def down
    # no-op
  end
end
