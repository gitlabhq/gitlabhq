# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Removes obsolete wiki notes
    class RemoveSelfManagedWikiNotes < BatchedMigrationJob
      def perform
        each_sub_batch(
          operation_name: :delete_all
        ) do |sub_batch|
          sub_batch.where(noteable_type: 'Wiki').delete_all
        end
      end
    end
  end
end
