# frozen_string_literal: true

module Packages
  module Nuget
    class SyncMetadatumService
      include Gitlab::Utils::StrongMemoize

      def initialize(package, metadata)
        @package = package
        @metadata = metadata
      end

      def execute
        if blank_metadata?
          metadatum.destroy! if metadatum.persisted?
        else
          metadatum.update!(
            license_url: license_url,
            project_url: project_url,
            icon_url: icon_url
          )
        end
      end

      private

      def metadatum
        strong_memoize(:metadatum) do
          @package.nuget_metadatum || @package.build_nuget_metadatum
        end
      end

      def blank_metadata?
        project_url.blank? && license_url.blank? && icon_url.blank?
      end

      def project_url
        @metadata[:project_url]
      end

      def license_url
        @metadata[:license_url]
      end

      def icon_url
        @metadata[:icon_url]
      end
    end
  end
end
