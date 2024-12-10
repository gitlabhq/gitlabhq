# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDefaultOrganizationOwnersAgain < BatchedMigrationJob
      operation_name :backfill_default_organization_owners_again # This is used as the key on collecting metrics
      scope_to ->(relation) { relation.where(admin: true) }
      feature_category :cell

      module Organizations
        class OrganizationUser < ApplicationRecord
          self.table_name = 'organization_users'
          self.inheritance_column = :_type_disabled
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          organization_users_attributes = sub_batch.map do |user|
            {
              user_id: user.id,
              organization_id: ::Organizations::Organization::DEFAULT_ORGANIZATION_ID,
              access_level: Gitlab::Access::OWNER
            }
          end

          ::Organizations::OrganizationUser.upsert_all(
            organization_users_attributes,
            returning: false,
            unique_by: [:organization_id, :user_id]
          )
        end
      end
    end
  end
end
