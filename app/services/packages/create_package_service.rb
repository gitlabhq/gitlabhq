# frozen_string_literal: true

module Packages
  class CreatePackageService < BaseService
    protected

    def find_or_create_package!(package_type, name: params[:name], version: params[:version])
      project
        .packages
        .with_package_type(package_type)
        .safe_find_or_create_by!(name: name, version: version) do |pkg|
          pkg.creator = package_creator
          yield pkg if block_given?
        end
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
        creator: package_creator,
        name: params[:name],
        version: params[:version]
      }.merge(attrs)
    end

    def package_creator
      current_user if current_user.is_a?(User)
    end
  end
end
