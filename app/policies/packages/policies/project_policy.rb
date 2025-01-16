# frozen_string_literal: true

module Packages
  module Policies
    class ProjectPolicy < BasePolicy
      delegate(:project) { @subject.project }

      overrides(:read_package)

      condition(:packages_enabled_for_everyone, scope: :subject) do
        @subject.package_registry_access_level == ProjectFeature::PUBLIC &&
          Gitlab::CurrentSettings.package_registry_allow_anyone_to_pull_option
      end

      condition(:allow_guest_plus_roles_to_pull_packages_enabled, scope: :subject) do
        Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, @subject.project.root_ancestor)
      end

      rule { project.packages_disabled }.policy do
        prevent(:read_package)
      end

      # TODO: Remove with the rollout of the FF allow_guest_plus_roles_to_pull_packages
      # https://gitlab.com/gitlab-org/gitlab/-/issues/512210
      rule { can?(:reporter_access) }.policy do
        enable :read_package
      end

      rule { can?(:public_access) }.policy do
        enable :read_package
      end

      rule { can?(:guest_access) & allow_guest_plus_roles_to_pull_packages_enabled }.policy do
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

      rule { project.public_or_internal & project.job_token_package_registry }.policy do
        enable :read_package
      end
    end
  end
end

Packages::Policies::ProjectPolicy.prepend_mod_with('Packages::Policies::ProjectPolicy')
