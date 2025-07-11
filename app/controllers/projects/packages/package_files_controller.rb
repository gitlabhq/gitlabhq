# frozen_string_literal: true

module Projects
  module Packages
    class PackageFilesController < ApplicationController
      include PackagesAccess
      include SendFileUpload

      feature_category :package_registry

      def download
        package_file = project.package_files.find(params.permit(:id)[:id])

        package_file.package.touch_last_downloaded_at

        log_enabled = package_file.package.generic? && Feature.enabled?(:packages_generic_package_content_type, project)

        send_upload(package_file.file, attachment: package_file.file_name_for_download,
          ssrf_params: ::Packages::SsrfProtection.params_for(package_file.package), log_enabled: log_enabled)
      end
    end
  end
end
