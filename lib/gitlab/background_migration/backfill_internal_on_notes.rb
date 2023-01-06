# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # This syncs the data to `internal` from `confidential` as we rename the column.
    class BackfillInternalOnNotes < BatchedMigrationJob
      scope_to -> (relation) { relation.where(confidential: true) }
      operation_name :update_all
      feature_category :database

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.update_all(internal: true)
        end
      end
    end
  end
end
