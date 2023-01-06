# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Removes obsolete wiki notes
    class RemoveSelfManagedWikiNotes < BatchedMigrationJob
      operation_name :delete_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.where(noteable_type: 'Wiki').delete_all
        end
      end
    end
  end
end
