# frozen_string_literal: true

module Packages
  module Conan
    class CreatePackageFileService
      include Gitlab::Utils::StrongMemoize

      def initialize(package, file, params)
        @package = package
        @file = file
        @params = params
      end

      def execute
        package_file = nil
        ApplicationRecord.transaction do
          package_file = package.package_files.build(
            file: file,
            size: params['file.size'],
            file_name: params[:file_name],
            file_sha1: params['file.sha1'],
            file_md5: params['file.md5'],
            conan_file_metadatum_attributes: {
              conan_file_type: params[:conan_file_type],
              package_reference_id: package_reference_id,
              recipe_revision_id: recipe_revision_id
            }
          )

          if params[:build].present?
            package_file.package_file_build_infos << package_file.package_file_build_infos.build(pipeline: params[:build].pipeline)
          end

          package_file.save!
        end

        ServiceResponse.success(payload: { package_file: package_file })
      rescue ActiveRecord::RecordInvalid => e
        ServiceResponse.error(message: e.message, reason: :invalid_package_file)
      end

      private

      attr_reader :package, :file, :params

      def package_reference_id
        return unless params[:conan_package_reference].present?

        package_reference_result = ::Packages::Conan::UpsertPackageReferenceService.new(package, params[:conan_package_reference], recipe_revision_id).execute!
        package_reference_result[:package_reference_id]
      end

      def recipe_revision_id
        unless params[:recipe_revision].present? && params[:recipe_revision] != ::Packages::Conan::FileMetadatum::DEFAULT_REVISION
          return
        end

        recipe_reference_result = ::Packages::Conan::UpsertRecipeRevisionService.new(package, params[:recipe_revision]).execute!
        recipe_reference_result[:recipe_revision_id]
      end
      strong_memoize_attr :recipe_revision_id
    end
  end
end
