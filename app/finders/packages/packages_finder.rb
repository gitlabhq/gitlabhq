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
                        .including_project_namespace_route
                        .including_tags
      packages = packages.preload_pipelines if preload_pipelines

      packages = filter_with_version(packages)
      packages = filter_by_package_type(packages)
      packages = filter_by_package_name(packages)
      packages = filter_by_status(packages)
      packages = filter_by_package_version(packages)
      order_packages(packages)
    end

    private

    attr_reader :params, :project

    def order_packages(packages)
      packages.sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")
    end

    def preload_pipelines
      params.fetch(:preload_pipelines, true)
    end
  end
end
