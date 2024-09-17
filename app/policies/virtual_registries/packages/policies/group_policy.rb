# frozen_string_literal: true

module VirtualRegistries
  module Packages
    module Policies
      class GroupPolicy < ::BasePolicy
        include CrudPolicyHelpers

        delegate(:group) { @subject.group }

        condition(:deploy_token_user, scope: :user, score: 0) { @user.is_a?(DeployToken) }

        condition(:deploy_token_can_read_virtual_registry, score: 10) do
          @user.read_virtual_registry && @user.has_access_to_group?(@subject.group)
        end

        rule { anonymous }.policy do
          prevent(*create_read_update_admin_destroy(:virtual_registry))
        end

        rule { group.guest | admin | group.has_projects }.policy do
          enable :read_virtual_registry
        end

        rule { group.maintainer }.policy do
          enable :create_virtual_registry
          enable :update_virtual_registry
          enable :destroy_virtual_registry
        end

        rule { deploy_token_user & deploy_token_can_read_virtual_registry }.policy do
          enable :read_virtual_registry
        end

        rule { deploy_token_user & ~deploy_token_can_read_virtual_registry }.policy do
          prevent :read_virtual_registry
        end
      end
    end
  end
end
