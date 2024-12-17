# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class CreateMissingTerraformModuleMetadata < BatchedMigrationJob
      TERRAFORM_MODULE_PACKAGE_TYPE = 12
      INSTALLABLE_STATUSES = [0, 1].freeze

      operation_name :enqueue_process_package_file_worker
      feature_category :package_registry

      scope_to ->(relation) do
        relation
          .where(package_type: TERRAFORM_MODULE_PACKAGE_TYPE)
          .where(status: INSTALLABLE_STATUSES)
          .where(created_at: Date.parse('2024-10-18').beginning_of_day..Date.parse('2024-10-18').end_of_day)
      end

      module Packages
        module TerraformModule
          class Metadatum < ApplicationRecord
            self.table_name = 'packages_terraform_module_metadata'
          end
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          subquery = Packages::TerraformModule::Metadatum
                       .select(1)
                       .where('packages_terraform_module_metadata.package_id = packages_packages.id')

          sub_batch
            .joins('INNER JOIN packages_package_files ON packages_package_files.package_id = packages_packages.id')
            .select('packages_package_files.id')
            .where('NOT EXISTS (?)', subquery)
            .find_each.with_index do |entry, index|
            ::Packages::TerraformModule::ProcessPackageFileWorker.perform_in((1 * index).seconds, entry.id)
          end
        end
      end
    end
  end
end
