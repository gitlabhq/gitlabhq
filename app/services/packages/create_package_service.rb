# frozen_string_literal: true

module Packages
  class CreatePackageService < BaseService
    protected

    def find_or_create_package!(package_type, name: params[:name], version: params[:version])
      project
        .packages
        .with_package_type(package_type)
        .safe_find_or_create_by!(name: name, version: version)
    end

    def create_package!(package_type, attrs = {})
      project
        .packages
        .with_package_type(package_type)
        .create!(package_attrs(attrs))
    end

    private

    def package_attrs(attrs)
      {
        name: params[:name],
        version: params[:version]
      }.merge(attrs)
    end
  end
end
