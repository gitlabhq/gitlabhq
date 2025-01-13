# frozen_string_literal: true

module API
  module Helpers
    module Packages
      module Maven
        extend Grape::API::Helpers

        SHA1_CHECKSUM_HEADER = 'x-checksum-sha1'
        MD5_CHECKSUM_HEADER = 'x-checksum-md5'

        params :path_and_file_name do
          requires :path,
            type: String,
            file_path: true,
            desc: 'Package path',
            documentation: { example: 'foo/bar/mypkg/1.0-SNAPSHOT' }
          requires :file_name,
            type: String,
            file_path: true,
            desc: 'Package file name',
            documentation: { example: 'mypkg-1.0-SNAPSHOT.jar' }
        end

        def extract_format(file_name, skip_fips_check: false)
          name, _, format = file_name.rpartition('.')

          if %w[md5 sha1].include?(format)
            unprocessable_entity! if !skip_fips_check && Gitlab::FIPS.enabled? && format == 'md5'

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
          ).execute&.last
        end

        def project
          nil
        end

        def group
          nil
        end

        def download_package_file!(package_file)
          package_file.package.touch_last_downloaded_at
          file = package_file.file

          extra_response_headers = { SHA1_CHECKSUM_HEADER => package_file.file_sha1 }
          extra_response_headers[MD5_CHECKSUM_HEADER] = package_file.file_md5 unless Gitlab::FIPS.enabled?

          present_carrierwave_file!(
            file,
            supports_direct_download: false, # we can't support direct download if we have custom response headers
            extra_response_headers: extra_response_headers
          )
        end
      end
    end
  end
end
