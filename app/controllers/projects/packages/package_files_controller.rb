# frozen_string_literal: true

module Projects
  module Packages
    class PackageFilesController < ApplicationController
      include PackagesAccess
      include SendFileUpload

      feature_category :package_registry

      def download
        package_file = project.package_files.find(params[:id])

        send_upload(package_file.file, attachment: package_file.file_name)
      end
    end
  end
end
