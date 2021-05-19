# frozen_string_literal: true

module Packages
  class PackagesFinder
    include ::Packages::FinderHelper

    def initialize(project, params = {})
      @project = project
      @params = params

      params[:order_by] ||= 'created_at'
      params[:sort] ||= 'asc'
    end

    def execute
      packages = project.packages
                        .including_build_info
                        .including_project_route
                        .including_tags
      packages = filter_with_version(packages)
      packages = filter_by_package_type(packages)
      packages = filter_by_package_name(packages)
      packages = filter_by_status(packages)
      order_packages(packages)
    end

    private

    attr_reader :params, :project

    def order_packages(packages)
      packages.sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")
    end
  end
end
