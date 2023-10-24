# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Source
          class ContainerScanning < BaseSource
            REQUIRED_ATTRIBUTES = [
              %w[image name],
              %w[image tag]
            ].freeze

            OPERATING_SYSTEM_ATTRIBUTES = [
              %w[operating_system name],
              %w[operating_system version]
            ].freeze

            private

            def type
              :container_scanning
            end

            def required_attributes_present?
              operating_system_attributes_valid? && super
            end

            def operating_system_attributes_valid?
              return true if data['operating_system'].blank?

              OPERATING_SYSTEM_ATTRIBUTES.all? do |keys|
                data.dig(*keys).present?
              end
            end
          end
        end
      end
    end
  end
end
