# frozen_string_literal: true

module Packages
  module Pypi
    class CreatePackageService < ::Packages::CreatePackageService
      include ::Gitlab::Utils::StrongMemoize

      def execute
        ::Packages::Package.transaction do
          Packages::Pypi::Metadatum.upsert(
            package_id: created_package.id,
            required_python: params[:requires_python]
          )

          ::Packages::CreatePackageFileService.new(created_package, file_params).execute
        end
      end

      private

      def created_package
        strong_memoize(:created_package) do
          find_or_create_package!(:pypi)
        end
      end

      def file_params
        {
          file: params[:content],
          file_name: params[:content].original_filename,
          file_md5: params[:md5_digest],
          file_sha256: params[:sha256_digest]
        }
      end
    end
  end
end
