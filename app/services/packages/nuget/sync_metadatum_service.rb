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
            authors: authors,
            description: description,
            license_url: license_url,
            project_url: project_url,
            icon_url: icon_url,
            project_id: package.project_id
          )
        end
      end

      private

      attr_reader :package, :metadata

      def metadatum
        package.nuget_metadatum || package.build_nuget_metadatum
      end
      strong_memoize_attr :metadatum

      def blank_metadata?
        [authors, description, project_url, license_url, icon_url].all?(&:blank?)
      end

      def authors
        truncate_value(:authors, ::Packages::Nuget::Metadatum::MAX_AUTHORS_LENGTH)
      end
      strong_memoize_attr :authors

      def description
        truncate_value(:description, ::Packages::Nuget::Metadatum::MAX_DESCRIPTION_LENGTH)
      end
      strong_memoize_attr :description

      def project_url
        metadata[:project_url]
      end

      def license_url
        metadata[:license_url]
      end

      def icon_url
        metadata[:icon_url]
      end

      def truncate_value(field, max_length)
        return unless metadata[field]

        if metadata[field].size > max_length
          log_info("#{field.capitalize} is too long (maximum is #{max_length} characters)", field)
        end

        metadata[field].truncate(max_length)
      end

      def log_info(message, field)
        Gitlab::AppLogger.info(
          class: self.class.name,
          message: message,
          package_id: package.id,
          project_id: package.project_id,
          field => metadata[field]
        )
      end
    end
  end
end
