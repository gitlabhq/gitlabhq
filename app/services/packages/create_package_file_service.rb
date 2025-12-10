# frozen_string_literal: true
module Packages
  class CreatePackageFileService
    def initialize(package, params)
      @package = package
      @params = params
    end

    def execute
      package_file = package.package_files.build(
        {
          file: params[:file],
          size: params[:size],
          file_name: params[:file_name],
          file_sha1: params[:file_sha1],
          file_sha256: params[:file_sha256],
          file_md5: params[:file_md5],
          status: params[:status],
          project_id: package.project_id
        }.compact_blank
      )

      if params[:build].present?
        package_file.package_file_build_infos << package_file.package_file_build_infos.build(pipeline: params[:build].pipeline)
      end

      package_file.save!
      package_file
    end

    private

    attr_reader :package, :params
  end
end
