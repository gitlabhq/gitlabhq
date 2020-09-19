# frozen_string_literal: true

module Packages
  class PackagesFinder
    attr_reader :params, :project

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
                        .processed
                        .has_version
      packages = filter_by_package_type(packages)
      packages = filter_by_package_name(packages)
      packages = order_packages(packages)
      packages
    end

    private

    def filter_by_package_type(packages)
      return packages unless params[:package_type]

      packages.with_package_type(params[:package_type])
    end

    def filter_by_package_name(packages)
      return packages unless params[:package_name]

      packages.search_by_name(params[:package_name])
    end

    def order_packages(packages)
      packages.sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")
    end
  end
end
