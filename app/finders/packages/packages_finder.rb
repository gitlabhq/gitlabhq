# frozen_string_literal: true

module Packages
  class PackagesFinder
    include ::Packages::FinderHelper

    # @param projects [Project, Array<Project>, ActiveRecord::Relation<Project>]
    # a single project, collection of projects, or projects relation
    # @param params [Hash] filtering and sorting options
    # @option params [String] :order_by ('created_at') attribute to order by
    # @option params [String] :sort ('asc') sort direction
    # @option params [String] :package_name filter by package name
    # @option params [String] :package_type filter by package type
    # @option params [String] :package_version filter by version
    # @option params [Boolean] :preload_pipelines (true) whether to preload pipelines
    # @option params [Boolean] :include_versionless include packages without version
    # @option params [Boolean] :exact_name whether to match package name exactly or not
    def initialize(projects, params = {})
      @projects = projects
      @params = params

      params[:order_by] ||= 'created_at'
      params[:sort] ||= 'asc'
    end

    def execute
      packages = base.including_project_namespace_route
                     .including_tags
                     .for_projects(projects)
      packages = packages.preload_pipelines if preload_pipelines

      packages = filter_with_version(packages)
      packages = filter_by_name(packages)
      packages = filter_by_status(packages)
      packages = filter_by_package_version(packages)
      order_packages(packages)
    end

    private

    attr_reader :params, :projects

    def filter_by_name(packages)
      return filter_by_exact_package_name(packages) if params[:exact_name]

      filter_by_package_name(packages)
    end

    def order_packages(packages)
      packages.sort_by_attribute("#{params[:order_by]}_#{params[:sort]}")
    end

    def preload_pipelines
      params.fetch(:preload_pipelines, true)
    end

    def base
      return ::Packages::Package.without_package_type(:terraform_module) unless package_type

      ::Packages::Package.package_type_to_class!(package_type.to_sym)
    end
  end
end
