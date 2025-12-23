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
            project_id: package.project_id,
            conan_file_metadatum_attributes: {
              conan_file_type: params[:conan_file_type],
              package_reference_id: package_reference_id,
              recipe_revision_id: recipe_revision_id,
              package_revision_id: package_revision_id
            }
          )

          if params[:build].present?
            package_file.package_file_build_infos << package_file.package_file_build_infos.build(pipeline: params[:build].pipeline)
          end

          package_file.save!

          # Conan sorts the files before the upload and the last one is always "conanmanifest.txt"
          # https://github.com/conan-io/conan/blob/9826fbd57f43b847d22d4530dfe40f015f4dc9e5/conan/internal/rest/rest_client_v2.py#L303
          # Conan server updates the "latest" revision after "conanmanifest.txt" is uploaded:
          # https://github.com/conan-io/conan/blob/9826fbd57f43b847d22d4530dfe40f015f4dc9e5/conans/server/service/v2/service_v2.py#L47
          # https://github.com/conan-io/conan/blob/9826fbd57f43b847d22d4530dfe40f015f4dc9e5/conans/server/service/v2/service_v2.py#L110
          update_revision_status if package_file.file_name == ::Packages::Conan::FileMetadatum::MANIFEST_FILE
        end

        if package_file.file_name == ::Packages::Conan::FileMetadatum::CONANINFO_TXT
          ::Packages::Conan::ProcessPackageFileWorker.perform_async(package_file.id)
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
      strong_memoize_attr :package_reference_id

      def recipe_revision_id
        unless params[:recipe_revision].present? && params[:recipe_revision] != ::Packages::Conan::FileMetadatum::DEFAULT_REVISION
          return
        end

        recipe_reference_result = ::Packages::Conan::UpsertRecipeRevisionService.new(package, params[:recipe_revision], recipe_revision_status).execute!
        recipe_reference_result[:recipe_revision_id]
      end
      strong_memoize_attr :recipe_revision_id

      def package_revision_id
        unless params[:package_revision].present? && params[:package_revision] != ::Packages::Conan::FileMetadatum::DEFAULT_REVISION
          return
        end

        return unless package_reference_id.present?

        package_revision_result = ::Packages::Conan::UpsertPackageRevisionService.new(package, package_reference_id, params[:package_revision]).execute!
        package_revision_result[:package_revision_id]
      end
      strong_memoize_attr :package_revision_id

      def recipe_revision_status
        recipe_file? ? :processing : :default
      end

      def update_revision_status
        model, id = if recipe_file?
                      [::Packages::Conan::RecipeRevision, recipe_revision_id]
                    else
                      [::Packages::Conan::PackageRevision, package_revision_id]
                    end

        model.id_in(id).update_all(status: model.statuses[:default])
      end

      def recipe_file?
        params[:conan_file_type] == :recipe_file
      end
    end
  end
end
