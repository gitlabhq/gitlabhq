# frozen_string_literal: true

module Gitlab
  module BackgroundOperation
    class UsersDeleteUnconfirmedSecondaryEmails < BaseOperationWorker
      operation_name :delete_all
      feature_category :user_management
      cursor :id

      # rubocop:disable CodeReuse/ActiveRecord -- Specific use-case
      def perform
        each_sub_batch do |sub_batch|
          sub_batch
            .where('created_at < ? AND confirmed_at IS NULL', created_cut_off)
            .delete_all
        end
      end
      # rubocop:enable CodeReuse/ActiveRecord

      private

      def created_cut_off
        ApplicationSetting::USERS_UNCONFIRMED_SECONDARY_EMAILS_DELETE_AFTER_DAYS.days.ago
      end
    end
  end
end
