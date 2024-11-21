# frozen_string_literal: true

module Packages
  module Rubygems
    class CreatePackageFileService
      def initialize(package:, params: {})
        @package = package
        @params = params
      end

      def execute
        unless package.present?
          return ServiceResponse.error(message: 'Package is required', reason: :package_is_required)
        end

        package_file = ::Packages::CreatePackageFileService.new(package, params).execute

        package_file.run_after_commit_or_now do
          ::Packages::Rubygems::ExtractionWorker.perform_async(package_file.id)
        end

        ServiceResponse.success(payload: { package_file: package_file })
      end

      private

      attr_reader :package, :params
    end
  end
end
