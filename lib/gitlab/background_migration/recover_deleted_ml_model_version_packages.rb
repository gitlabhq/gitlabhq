# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    class RecoverDeletedMlModelVersionPackages < BatchedMigrationJob
      ML_MODEL_PACKAGE_TYPE = 14

      operation_name :recover_deleted_ml_model_version_packages
      scope_to ->(relation) { relation.where(package_id: nil) }
      feature_category :mlops

      class Package < ::ApplicationRecord
        self.table_name = 'packages_packages'
      end

      class Model < ::ApplicationRecord
        self.table_name = 'ml_models'
      end

      def perform
        each_sub_batch do |sub_batch|
          sub_batch.each do |ml_model_version|
            Model.transaction do
              ml_model = Model.find(ml_model_version.model_id)
              package = Package.create!(
                project_id: ml_model_version.project_id,
                name: ml_model.name,
                version: ml_model_version.version,
                package_type: ML_MODEL_PACKAGE_TYPE
              )
              ml_model_version.update! package_id: package.id
            end
          end
        end
      end
    end
  end
end
