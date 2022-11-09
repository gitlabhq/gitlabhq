# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Component
          attr_reader :component_type, :name, :version

          def initialize(type:, name:, purl:, version:)
            @component_type = type
            @name = name
            @purl = purl
            @version = version
          end

          def ingestible?
            supported_component_type? && supported_purl_type?
          end

          def purl
            return unless @purl

            ::Sbom::PackageUrl.parse(@purl)
          end

          private

          def supported_component_type?
            ::Enums::Sbom.component_types.include?(component_type.to_sym)
          end

          def supported_purl_type?
            return true unless purl

            ::Enums::Sbom.purl_types.include?(purl.type.to_sym)
          end
        end
      end
    end
  end
end
