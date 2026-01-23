# frozen_string_literal: true

module Projects
  module Packages
    class PackageFilesController < ApplicationController
      include PackagesAccess
      include SendFileUpload

      feature_category :package_registry

      def download
        package_file = ::Packages::PackageFile.for_projects(project).find(params.permit(:id)[:id])
        package = package_file.package

        package.touch_last_downloaded_at

        send_upload(package_file.file, attachment: package_file.file_name_for_download,
          ssrf_params: ::Packages::SsrfProtection.params_for(package_file.package),
          sanitize_content_type: package.generic?)
      end
    end
  end
end
