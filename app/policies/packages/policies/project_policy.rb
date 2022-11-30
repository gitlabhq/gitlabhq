# frozen_string_literal: true

module Packages
  module Policies
    class ProjectPolicy < BasePolicy
      delegate(:project) { @subject.project }

      overrides(:read_package)

      condition(:package_registry_access_level_feature_flag_enabled, scope: :subject) do
        ::Feature.enabled?(:package_registry_access_level, @subject)
      end

      condition(:packages_enabled_for_everyone, scope: :subject) do
        @subject.package_registry_access_level == ProjectFeature::PUBLIC
      end

      # This rule can be removed if the `package_registry_access_level` feature flag is removed.
      # Reason: If the feature flag is globally enabled, this rule will never be executed.
      rule { anonymous & ~project.public_project & ~package_registry_access_level_feature_flag_enabled }.prevent_all

      # This rule can be removed if the `package_registry_access_level` feature flag is removed.
      # Reason: If the feature flag is globally enabled, this rule will never be executed.
      rule do
        ~project.public_project & ~project.internal_access &
          ~project.project_allowed_for_job_token & ~package_registry_access_level_feature_flag_enabled
      end.prevent_all

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

      rule { package_registry_access_level_feature_flag_enabled & packages_enabled_for_everyone }.policy do
        enable :read_package
      end
    end
  end
end

Packages::Policies::ProjectPolicy.prepend_mod_with('Packages::Policies::ProjectPolicy')
