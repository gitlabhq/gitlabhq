# frozen_string_literal: true

module Packages
  module Npm
    class PackageFinder
      include ::Packages::FinderHelper

      delegate :last, to: :execute

      def initialize(project: nil, namespace: nil, params: {})
        @project = project
        @namespace = namespace
        @params = params
      end

      def execute
        return ::Packages::Package.none unless params[:package_name].present?

        packages = if Feature.enabled?(:npm_extract_npm_package_model, Feature.current_request)
                     base.installable
                   else
                     base.npm.installable
                   end

        packages = filter_by_exact_package_name(packages)
        filter_by_package_version(packages)
      end

      private

      attr_reader :project, :namespace, :params

      def base
        if project
          packages_for_project
        elsif namespace
          packages_for_namespace
        else
          packages_class.none
        end
      end

      def packages_for_project
        if Feature.enabled?(:npm_extract_npm_package_model, Feature.current_request)
          ::Packages::Npm::Package.for_projects(project)
        else
          project.packages
        end
      end

      def packages_for_namespace
        packages_class.for_projects(namespace.all_projects)
      end

      # TODO: Use the class directly with the rollout of the FF npm_extract_npm_package_model
      # https://gitlab.com/gitlab-org/gitlab/-/issues/501469
      def packages_class
        if Feature.enabled?(:npm_extract_npm_package_model, Feature.current_request)
          ::Packages::Npm::Package
        else
          ::Packages::Package
        end
      end
    end
  end
end
