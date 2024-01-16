# frozen_string_literal: true

module Gitlab
  module Database
    module PartitioningMigrationHelpers
      include ForeignKeyHelpers
      include TableManagementHelpers
      include IndexHelpers
      include UniquenessHelpers
    end
  end
end
