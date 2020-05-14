# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      class PartitionedForeignKey < ApplicationRecord
        validates_with PartitionedForeignKeyValidator

        scope :by_referenced_table, ->(table) { where(to_table: table) }
      end
    end
  end
end
