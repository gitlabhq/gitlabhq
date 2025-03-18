# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CreateMissingNugetSymbolFiles < BatchedMigrationJob
      NUGET_PACKAGE_TYPE = 4
      INSTALLABLE_STATUSES = [0, 1].freeze

      operation_name :enqueue_extraction_worker
      feature_category :package_registry

      scope_to ->(relation) do
        relation
          .where(created_at: Date.parse('2024-11-08').beginning_of_day..Date.parse('2024-11-11').end_of_day)
          .where(package_type: NUGET_PACKAGE_TYPE)
      end

      module Packages
        module Nuget
          class Symbol < ApplicationRecord
            self.table_name = 'packages_nuget_symbols'
          end
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          subquery = Packages::Nuget::Symbol
                       .select(1)
                       .where('packages_nuget_symbols.package_id = packages_packages.id')

          sub_batch
            .joins('INNER JOIN packages_package_files ON packages_package_files.package_id = packages_packages.id')
            .where(status: INSTALLABLE_STATUSES)
            .select('packages_package_files.id')
            .where('NOT EXISTS (?)', subquery)
            .find_each.with_index do |entry, index|
            ::Packages::Nuget::CreateSymbolsWorker.perform_in((1 * index).seconds, entry.id)
          end
        end
      end
    end
  end
end
