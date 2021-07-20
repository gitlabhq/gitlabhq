# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class Package < Base
      attr_accessor :name

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'project-with-package'
          resource.description = 'Project with Package'
        end
      end

      attribute :id do
        this_package = project.packages
                              &.find { |package| package[:name] == name }

        this_package.try(:fetch, :id)
      end

      def fabricate!
      end

      def fabricate_via_api!
        resource_web_url(api_get)
      rescue ResourceNotFoundError
        super
      end

      def remove_via_api!
        packages = project.packages

        if packages && !packages.empty?
          QA::Runtime::Logger.debug("Deleting package '#{name}' from '#{project.path_with_namespace}' via API")
          super
        end
      end

      def api_delete_path
        "/projects/#{project.id}/packages/#{id}"
      end

      def api_get_path
        "/projects/#{project.id}/packages"
      end
    end
  end
end
