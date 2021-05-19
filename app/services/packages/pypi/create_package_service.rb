# frozen_string_literal: true

module Packages
  module Pypi
    class CreatePackageService < ::Packages::CreatePackageService
      include ::Gitlab::Utils::StrongMemoize

      def execute
        ::Packages::Package.transaction do
          meta = Packages::Pypi::Metadatum.new(
            package: created_package,
            required_python: params[:requires_python]
          )

          unless meta.valid?
            raise ActiveRecord::RecordInvalid, meta
          end

          Packages::Pypi::Metadatum.upsert(meta.attributes)

          ::Packages::CreatePackageFileService.new(created_package, file_params).execute

          created_package
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
          build: params[:build],
          file: params[:content],
          file_name: params[:content].original_filename,
          file_md5: params[:md5_digest],
          file_sha256: params[:sha256_digest]
        }
      end
    end
  end
end
