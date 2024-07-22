# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class BackfillUserDetails < BatchedMigrationJob
      operation_name :backfill_user_details # This is used as the key on collecting metrics
      feature_category :acquisition

      class UserDetail < ApplicationRecord
        self.table_name = :user_details
      end

      def perform
        each_sub_batch do |sub_batch|
          records_need_created_for_user_ids = sub_batch
                                                .joins("LEFT JOIN user_details ON (users.id = user_details.user_id)")
                                                .where(user_details: { user_id: nil })
                                                .ids

          next if records_need_created_for_user_ids.empty?

          user_details_attributes = records_need_created_for_user_ids.map do |user_id|
            {
              user_id: user_id
            }
          end

          # This should be safe so we do not hit the fk_rails_12e0b3043d constraint
          # since we already prequalified in the query above that no user_details
          # record exists for that user.
          # However, to be sure, we'll rescue here in case there is some extreme
          # edge case.
          UserDetail.upsert_all(user_details_attributes, returning: false)
        rescue Exception => e # rubocop:disable Lint/RescueException -- following https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#best-practices re-raise
          logger.error(
            class: e.class,
            message: "BackfillUserDetails Migration: error inserting. Reason: #{e.message}",
            user_ids: records_need_created_for_user_ids
          )

          raise
        end
      end

      private

      def logger
        @logger ||= Gitlab::BackgroundMigration::Logger.build
      end
    end
  end
end
