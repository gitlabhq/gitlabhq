# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillDefaultOrganizationUsers < BatchedMigrationJob
      operation_name :backfill_default_organization_users # This is used as the key on collecting metrics
      scope_to ->(relation) { relation.where(admin: false) } # true handled in BackfillDefaultOrganizationOwnersAgain
      feature_category :cell

      DEFAULT_ACCESS_LEVEL = 10
      DEFAULT_ORGANIZATION_ID = 1

      module Organizations
        class OrganizationUser < ApplicationRecord
          self.table_name = 'organization_users'
          self.inheritance_column = :_type_disabled
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          organization_users_attributes = sub_batch.select(:id).map do |user|
            {
              user_id: user.id,
              organization_id: DEFAULT_ORGANIZATION_ID,
              access_level: DEFAULT_ACCESS_LEVEL
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
