# frozen_string_literal: true

module Packages
  module Helm
    class CreatePackageFileService < ::Packages::CreatePackageFileService
      def execute
        package_file = super
        chart_name = extract_chart_name(package_file)

        return handle_error('Chart name not found.', :extraction_error) if chart_name.blank?
        return handle_error('Package protected.', :package_protected) if package_protected?(chart_name)

        ServiceResponse.success(payload: { package_file: package_file })
      rescue ::Packages::Helm::ExtractFileMetadataService::ExtractionError => e
        handle_error(e.message, :extraction_error)
      end

      private

      def extract_chart_name(package_file)
        ::Packages::Helm::ExtractFileMetadataService.new(package_file).execute['name']
      end

      def package_protected?(chart_name)
        ::Packages::Protection::CheckRuleExistenceService.for_push(
          project: package.project,
          current_user: package.creator,
          params: { package_name: chart_name, package_type: :helm }
        ).execute[:protection_rule_exists?]
      end

      def handle_error(message, reason)
        package.destroy
        ServiceResponse.error(message: message, reason: reason)
      end
    end
  end
end
