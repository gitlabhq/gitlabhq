# frozen_string_literal: true

module Gitlab
  module Database
    class BackgroundMigrationJob < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
      self.table_name = :background_migration_jobs

      scope :for_migration_execution, -> (class_name, arguments) do
        where('class_name = ? AND arguments = ?', class_name, arguments.to_json)
      end

      enum status: {
        pending: 0,
        succeeded: 1
      }

      def self.mark_all_as_succeeded(class_name, arguments)
        self.pending.for_migration_execution(class_name, arguments)
          .update_all("status = #{statuses[:succeeded]}, updated_at = NOW()")
      end
    end
  end
end
