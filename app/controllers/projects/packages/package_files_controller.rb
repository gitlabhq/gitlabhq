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

        send_upload(package_file.file, attachment: package_file.file_name_for_download)
      end
    end
  end
end
