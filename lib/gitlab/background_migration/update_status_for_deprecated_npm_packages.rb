# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class UpdateStatusForDeprecatedNpmPackages < BatchedMigrationJob
      operation_name :update_all
      scope_to ->(relation) { relation.where("package_json ? 'deprecated'") }
      feature_category :package_registry

      STATUS_DEPRECATED = 5

      module Packages
        class Package < ApplicationRecord
          self.table_name = 'packages_packages'
        end
      end

      def perform
        each_sub_batch do |sub_batch|
          Packages::Package.id_in(sub_batch.select(:package_id)).update_all(status: STATUS_DEPRECATED)
        end
      end
    end
  end
end
