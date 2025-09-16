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
      packages = base.including_project_namespace_route
                     .including_tags
      packages = packages.preload_pipelines if preload_pipelines

      packages = filter_with_version(packages)
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

    def base
      return ::Packages::Package.for_projects(project).without_package_type(:terraform_module) unless package_type

      package_class = ::Packages::Package.inheritance_column_to_class_map[package_type.to_sym]

      raise ArgumentError, "'#{package_type}' is not a valid package_type" unless package_class

      package_class.constantize.for_projects(project)
    end
  end
end
