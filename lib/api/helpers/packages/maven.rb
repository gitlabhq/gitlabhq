# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Maven
        extend Grape::API::Helpers

        params :path_and_file_name do
          requires :path,
            type: String,
            desc: 'Package path',
            documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT' }
          requires :file_name,
            type: String,
            desc: 'Package file name',
            documentation: { example: 'mypkg-1.0-SNAPSHOT.jar' }
        end

        def extract_format(file_name)
          name, _, format = file_name.rpartition('.')

          if %w[md5 sha1].include?(format)
            unprocessable_entity! if Gitlab::FIPS.enabled? && format == 'md5'

            [name, format]
          else
            [file_name, format]
          end
        end

        def fetch_package(file_name:, project: nil, group: nil)
          order_by_package_file = file_name.include?(::Packages::Maven::Metadata.filename) &&
            params[:path].exclude?(::Packages::Maven::FindOrCreatePackageService::SNAPSHOT_TERM)

          ::Packages::Maven::PackageFinder.new(
            current_user,
            project || group,
            path: params[:path],
            order_by_package_file: order_by_package_file
          ).execute
        end

        def project
          nil
        end

        def group
          nil
        end

        def present_carrierwave_file_with_head_support!(package_file, supports_direct_download: true)
          package_file.package.touch_last_downloaded_at
          file = package_file.file

          if head_request_on_aws_file?(file, supports_direct_download) && !file.file_storage?
            return redirect(signed_head_url(file))
          end

          present_carrierwave_file!(file, supports_direct_download: supports_direct_download)
        end

        def signed_head_url(file)
          fog_storage = ::Fog::Storage.new(file.fog_credentials)
          fog_dir = fog_storage.directories.new(key: file.fog_directory)
          fog_file = fog_dir.files.new(key: file.path)
          expire_at = ::Fog::Time.now + file.fog_authenticated_url_expiration

          fog_file.collection.head_url(fog_file.key, expire_at)
        end

        def head_request_on_aws_file?(file, supports_direct_download)
          Gitlab.config.packages.object_store.enabled &&
            supports_direct_download &&
            file.class.direct_download_enabled? &&
            request.head? &&
            file.fog_credentials[:provider] == 'AWS'
        end
      end
    end
  end
end
