# frozen_string_literal: true
module Packages
  class CreatePackageFileService
    attr_reader :package, :params

    def initialize(package, params)
      @package = package
      @params = params
    end

    def execute
      package.package_files.create!(
        file:      params[:file],
        size:      params[:size],
        file_name: params[:file_name],
        file_type: params[:file_type],
        file_sha1: params[:file_sha1],
        file_md5:  params[:file_md5]
      )
    end
  end
end
