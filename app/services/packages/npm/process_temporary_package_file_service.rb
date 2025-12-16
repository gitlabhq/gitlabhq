# frozen_string_literal: true

module Packages
  module Npm
    class ProcessTemporaryPackageFileService < ::BaseService
      ERRORS = {
        unauthorized: ServiceResponse.error(message: 'Unauthorized', reason: :unauthorized),
        missing_versions: ServiceResponse.error(message: 'Missing versions', reason: :missing_versions),
        missing_deprecated_versions: ServiceResponse.error(
          message: 'Missing deprecated versions',
          reason: :missing_deprecated_versions
        )
      }.freeze

      delegate :package, to: :package_file, private: true

      def initialize(package_file:, user:, params: {})
        super(package_file.project, user, params)

        @package_file = package_file
      end

      def execute
        json_doc = Gitlab::Json.parse(package_file.file.read)
        json_doc = json_doc.with_indifferent_access

        response = if params[:deprecate]
                     handle_deprecation(json_doc)
                   else
                     handle_creation(json_doc)
                   end

        response.error? ? response : ServiceResponse.success
      rescue JSON::ParserError => e
        ServiceResponse.error(message: e.message, reason: :json_parser_error)
      end

      private

      attr_reader :package_file

      def handle_deprecation(json_doc)
        return ERRORS[:missing_versions] unless json_doc.key?('versions')
        return ERRORS[:unauthorized] unless can_destroy_package?

        json_doc['versions'].select! { |_, version| version['deprecated'] }

        return ERRORS[:missing_deprecated_versions] unless json_doc['versions'].any?

        response = deprecate_package_versions(json_doc)
        return response if response.error?

        mark_package_for_destruction
      end

      def can_destroy_package?
        can?(current_user, :destroy_package, project)
      end

      def deprecate_package_versions(json_doc)
        ::Packages::Npm::DeprecatePackageService.new(project, json_doc).execute
      end

      def mark_package_for_destruction
        ::Packages::MarkPackageForDestructionService.new(container: package, current_user: current_user).execute
      end

      def handle_creation(json_doc)
        ::Packages::Npm::CreatePackageService
          .new(project, current_user, json_doc.merge(temp_package: package)).execute
      end
    end
  end
end
