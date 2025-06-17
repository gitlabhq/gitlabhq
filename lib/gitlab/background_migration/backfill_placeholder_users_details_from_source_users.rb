# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillPlaceholderUsersDetailsFromSourceUsers < BatchedMigrationJob
      operation_name :backfill_placeholder_users_details_from_source_users
      feature_category :importers

      class ImportSourceUser < ApplicationRecord
        self.table_name = 'import_source_users'

        belongs_to :namespace
      end

      class Namespace < ApplicationRecord
        self.table_name = 'namespaces'
      end

      class ImportPlaceholderUserDetail < ApplicationRecord
        self.table_name = 'import_placeholder_user_details'
      end

      def perform
        each_sub_batch do |sub_batch|
          backfill_placeholder_user_details(sub_batch)
        end
      end

      private

      def backfill_placeholder_user_details(sub_batch)
        source_users_with_data = prepare_source_users_data(sub_batch)
        return if source_users_with_data.empty?

        placeholder_user_ids = source_users_with_data.keys

        existing_placeholder_ids = get_existing_placeholder_ids(placeholder_user_ids)

        users_to_process = source_users_with_data.reject do |placeholder_id, _|
          existing_placeholder_ids.include?(placeholder_id)
        end
        return if users_to_process.empty?

        bulk_insert_placeholder_details(users_to_process)
      end

      def prepare_source_users_data(sub_batch)
        source_users = ImportSourceUser
          .where(id: sub_batch)
          .joins(:namespace)
          .where.not(placeholder_user_id: nil)
          .where.not(namespace_id: nil)
          .select(:placeholder_user_id, :namespace_id, 'namespaces.organization_id as organization_id')

        source_users.each_with_object({}) do |user, hash|
          hash[user.placeholder_user_id] = {
            namespace_id: user.namespace_id,
            organization_id: user.organization_id
          }
        end
      end

      def get_existing_placeholder_ids(placeholder_user_ids)
        return [] if placeholder_user_ids.empty?

        ImportPlaceholderUserDetail
          .where(placeholder_user_id: placeholder_user_ids)
          .pluck(:placeholder_user_id)
      end

      def bulk_insert_placeholder_details(users_data)
        return if users_data.empty?

        timestamp = Time.current

        records_to_insert = users_data.map do |placeholder_user_id, data|
          {
            placeholder_user_id: placeholder_user_id,
            namespace_id: data[:namespace_id],
            organization_id: data[:organization_id],
            created_at: timestamp,
            updated_at: timestamp
          }
        end

        begin
          ImportPlaceholderUserDetail.upsert_all(records_to_insert)
        rescue StandardError => e
          logger.error(
            message: "Error bulk creating placeholder user details: #{e.message}",
            count: users_data.size,
            placeholder_user_ids: users_data.keys
          )

          raise e
        end
      end

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
