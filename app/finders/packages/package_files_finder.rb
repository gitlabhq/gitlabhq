# frozen_string_literal: true

module Packages
  class PackageFilesFinder
    attr_reader :package, :params

    def initialize(package, params = {})
      @package = package
      @params = params
    end

    def execute
      package_files
    end

    private

    def package_files
      by_file_name(package.installable_package_files)
    end

    def by_file_name(files)
      return files unless params[:file_name]

      if params[:with_file_name_like]
        files.with_file_name_like(params[:file_name])
      else
        files.with_file_name(params[:file_name])
      end
    end
  end
end
