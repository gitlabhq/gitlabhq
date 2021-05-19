# frozen_string_literal: true

module Packages
  module TerraformModule
    class CreatePackageService < ::Packages::CreatePackageService
      include Gitlab::Utils::StrongMemoize

      def execute
        return error('Version is empty.', 400) if params[:module_version].blank?
        return error('Package already exists.', 403) if current_package_exists_elsewhere?
        return error('Package version already exists.', 403) if current_package_version_exists?
        return error('File is too large.', 400) if file_size_exceeded?

        ActiveRecord::Base.transaction { create_terraform_module_package! }
      end

      private

      def create_terraform_module_package!
        package = create_package!(:terraform_module, name: name, version: params[:module_version])

        ::Packages::CreatePackageFileService.new(package, file_params).execute

        package
      end

      def current_package_exists_elsewhere?
        ::Packages::Package
          .for_projects(project.root_namespace.all_projects.id_not_in(project.id))
          .with_package_type(:terraform_module)
          .with_name(name)
          .exists?
      end

      def current_package_version_exists?
        project.packages
          .with_package_type(:terraform_module)
          .with_name(name)
          .with_version(params[:module_version])
          .exists?
      end

      def name
        strong_memoize(:name) do
          "#{params[:module_name]}/#{params[:module_system]}"
        end
      end

      def file_name
        strong_memoize(:file_name) do
          "#{params[:module_name]}-#{params[:module_system]}-#{params[:module_version]}.tgz"
        end
      end

      def file_params
        {
          file: params[:file],
          size: params[:file].size,
          file_sha256: params[:file].sha256,
          file_name: file_name,
          build: params[:build]
        }
      end

      def file_size_exceeded?
        project.actual_limits.exceeded?(:generic_packages_max_file_size, params[:file].size)
      end
    end
  end
end
