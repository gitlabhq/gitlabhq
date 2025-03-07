# frozen_string_literal: true

module Packages
  module TerraformModule
    module Metadata
      class UpdateService
        delegate :terraform_module_metadatum, to: :package, private: true

        def initialize(package, metadata_hash)
          @package = package
          @metadata_hash = metadata_hash
        end

        def execute
          terraform_module_metadatum.assign_attributes(fields: metadata_hash)

          if terraform_module_metadatum.valid?
            ::Packages::TerraformModule::Metadatum.upsert(terraform_module_metadatum.attributes, returning: false)

            ServiceResponse.success(payload: { metadata: terraform_module_metadatum })
          else
            Gitlab::ErrorTracking.track_exception(
              ActiveRecord::RecordInvalid.new(terraform_module_metadatum),
              class: self.class.name,
              package_id: package.id
            )

            ServiceResponse.error(
              message: terraform_module_metadatum.errors.full_messages.to_sentence,
              reason: :bad_request
            )
          end
        end

        private

        attr_reader :package, :metadata_hash
      end
    end
  end
end
