# frozen_string_literal: true

module Packages
  class CreatePackageService < BaseService
    ERROR_RESPONSE_PACKAGE_PROTECTED = ServiceResponse.error(message: 'Package protected.', reason: :package_protected)

    protected

    def find_or_create_package!(packages_class, name: params[:name], version: params[:version])
      # safe_find_or_create_by! was originally called here.
      # We merely switched to `find_or_create_by!`
      # rubocop: disable CodeReuse/ActiveRecord
      packages_class
        .for_projects(project)
        .not_pending_destruction
        .find_or_create_by!(name: name, version: version) do |package|
          package.status = params[:status] if params[:status]
          package.creator = package_creator

          add_build_info(package)
        end
      # rubocop: enable CodeReuse/ActiveRecord
    end

    def create_package!(packages_class, attrs = {})
      packages_class
        .for_projects(project)
        .create!(package_attrs(attrs)) do |package|
          add_build_info(package)
        end
    end

    def can_create_package?
      can?(current_user, :create_package, project)
    end

    def package_protected?(package_name:, package_type:)
      service_response =
        ::Packages::Protection::CheckRuleExistenceService.for_push(
          project: project,
          current_user: current_user,
          params: { package_name: package_name, package_type: package_type }
        ).execute

      raise ArgumentError, service_response.message if service_response.error?

      service_response[:protection_rule_exists?]
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
