# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class DeleteTwitterIdentities < BatchedMigrationJob
      feature_category :system_access
      operation_name :delete_twitter_identities

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(provider: 'twitter').delete_all
        end
      end
    end
  end
end
