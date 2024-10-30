# frozen_string_literal: true

module Packages
  module TerraformModule
    module Metadata
      class CreateService
        def initialize(package, metadata_hash)
          @package = package
          @metadata_hash = metadata_hash
        end

        def execute
          metadata = ::Packages::TerraformModule::Metadatum.new(
            package: package,
            project: package.project,
            fields: metadata_hash,
            updated_at: Time.current,
            created_at: Time.current
          )

          if metadata.valid?
            ::Packages::TerraformModule::Metadatum.upsert(metadata.attributes, returning: false)

            ServiceResponse.success(payload: { metadata: metadata })
          else
            Gitlab::ErrorTracking.track_exception(
              ActiveRecord::RecordInvalid.new(metadata),
              class: self.class.name,
              package_id: package.id
            )

            ServiceResponse.error(message: metadata.errors.full_messages, reason: :bad_request)
          end
        end

        private

        attr_reader :package, :metadata_hash
      end
    end
  end
end
