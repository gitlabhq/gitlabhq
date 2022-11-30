# frozen_string_literal: true

module Packages
  module Policies
    class GroupPolicy < BasePolicy
      delegate(:group) { @subject.group }

      overrides(:read_package)

      rule { group.public_group }.policy do
        enable :read_package
      end

      rule { group.reporter }.policy do
        enable :read_package
      end

      rule { group.read_package_registry_deploy_token }.policy do
        enable :read_package
      end

      rule { group.write_package_registry_deploy_token }.policy do
        enable :read_package
      end
    end
  end
end

Packages::Policies::GroupPolicy.prepend_mod_with('Packages::Policies::GroupPolicy')
