# frozen_string_literal: true

module Gitlab
  module Database
    class BackgroundMigrationJob < ActiveRecord::Base # rubocop:disable Rails/ApplicationRecord
      self.table_name = :background_migration_jobs

      scope :for_migration_execution, -> (class_name, arguments) do
        where('class_name = ? AND arguments = ?', normalize_class_name(class_name), arguments.to_json)
      end

      enum status: {
        pending: 0,
        succeeded: 1
      }

      def self.mark_all_as_succeeded(class_name, arguments)
        self.pending.for_migration_execution(class_name, arguments)
          .update_all("status = #{statuses[:succeeded]}, updated_at = NOW()")
      end

      def self.normalize_class_name(class_name)
        return class_name unless class_name.present? && class_name.start_with?('::')

        class_name[2..]
      end

      def class_name=(value)
        write_attribute(:class_name, self.class.normalize_class_name(value))
      end
    end
  end
end
