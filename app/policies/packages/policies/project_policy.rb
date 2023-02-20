# frozen_string_literal: true

module Packages
  module Policies
    class ProjectPolicy < BasePolicy
      delegate(:project) { @subject.project }

      overrides(:read_package)

      condition(:packages_enabled_for_everyone, scope: :subject) do
        @subject.package_registry_access_level == ProjectFeature::PUBLIC
      end

      rule { project.packages_disabled }.policy do
        prevent(:read_package)
      end

      rule { can?(:reporter_access) }.policy do
        enable :read_package
      end

      rule { can?(:public_access) }.policy do
        enable :read_package
      end

      rule { project.read_package_registry_deploy_token }.policy do
        enable :read_package
      end

      rule { project.write_package_registry_deploy_token }.policy do
        enable :read_package
      end

      rule { packages_enabled_for_everyone }.policy do
        enable :read_package
      end
    end
  end
end

Packages::Policies::ProjectPolicy.prepend_mod_with('Packages::Policies::ProjectPolicy')
