# frozen_string_literal: true

module Packages
  module Policies
    class GroupPolicy < BasePolicy
      delegate(:group) { @subject.group }

      overrides(:read_package)

      # Because we need to defer the evaluation of this condition to be after :read_group is evaluated,
      # we put its score higher than the score of :read_group (122)
      condition(:has_projects_with_public_package_registry, scope: :subject, score: 150) do
        ::Gitlab::CurrentSettings.package_registry_allow_anyone_to_pull_option &&
          @subject.all_projects.with_public_package_registry.any?
      end

      condition(:allow_guest_plus_roles_to_pull_packages_enabled, scope: :subject) do
        Feature.enabled?(:allow_guest_plus_roles_to_pull_packages, @subject.root_ancestor)
      end

      rule { group.public_group }.policy do
        enable :read_package
      end

      # TODO: Remove with the rollout of the FF allow_guest_plus_roles_to_pull_packages
      # https://gitlab.com/gitlab-org/gitlab/-/issues/512210
      rule { group.reporter }.policy do
        enable :read_package
      end

      rule { group.read_package_registry_deploy_token }.policy do
        enable :read_package
      end

      rule { group.write_package_registry_deploy_token }.policy do
        enable :read_package
      end

      rule { can?(:read_group) | has_projects_with_public_package_registry }.policy do
        # We add a new permission and don't reuse :read_group here for two reasons:
        # 1. This's a bit of expensive rule to compute, so we need to narrow it down to a more targeted permission
        #    that only allows access to the public package registry in private/internal groups
        # 2. The :read_group permission is more broad and used in many places. This may grant access to other
        #    package-related actions that we don't want to.
        enable :read_package_within_public_registries
      end

      rule { group.guest & allow_guest_plus_roles_to_pull_packages_enabled }.policy do
        enable :read_package
      end
    end
  end
end

Packages::Policies::GroupPolicy.prepend_mod_with('Packages::Policies::GroupPolicy')
