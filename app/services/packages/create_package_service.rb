# frozen_string_literal: true

module Packages
  class CreatePackageService < BaseService
    protected

    def find_or_create_package!(package_type, name: params[:name], version: params[:version])
      project
        .packages
        .with_package_type(package_type)
        .safe_find_or_create_by!(name: name, version: version) do |package|
          package.status = params[:status] if params[:status]
          package.creator = package_creator

          add_build_info(package)
        end
    end

    def create_package!(package_type, attrs = {})
      project
        .packages
        .with_package_type(package_type)
        .create!(package_attrs(attrs)) do |package|
          add_build_info(package)
        end
    end

    private

    def package_attrs(attrs)
      {
        creator: package_creator,
        name: params[:name],
        version: params[:version],
        status: params[:status]
      }.compact.merge(attrs)
    end

    def package_creator
      current_user if current_user.is_a?(User)
    end

    def add_build_info(package)
      if params[:build].present?
        package.build_infos.new(pipeline: params[:build].pipeline)
      end
    end
  end
end
