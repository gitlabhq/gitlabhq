# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/database/batched_background_migrations.html
# for more information on how to use batched background migrations

# Update below commented lines with appropriate values.

module Gitlab
  module BackgroundMigration
    class RemoveInvalidOrganizationUsers < BatchedMigrationJob
      operation_name :remove_invalid_organization_users
      feature_category :organization

      class OrganizationUser < ::ApplicationRecord
        self.table_name = 'organization_users'

        belongs_to :user, inverse_of: :organization_users
        belongs_to :organization, inverse_of: :organization_users
      end

      class Organization < ::ApplicationRecord
        self.table_name = 'organizations'

        has_many :organization_users, inverse_of: :organization
      end

      class User < ::ApplicationRecord
        self.table_name = 'users'

        has_many :organization_users, inverse_of: :user
      end

      def perform
        each_sub_batch do |sub_batch|
          OrganizationUser.where(id: sub_batch).where.missing(:user).delete_all
          OrganizationUser.where(id: sub_batch).where.missing(:organization).delete_all
        end
      end
    end
  end
end
