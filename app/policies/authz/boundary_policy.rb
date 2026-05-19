# frozen_string_literal: true

module Authz
  class BoundaryPolicy < ::BasePolicy
    alias_method :token, :user
    alias_method :boundary, :subject

    condition(:granular_pat, score: 0) do
      token.is_a?(::PersonalAccessToken) && token.granular?
    end

    condition(:member) do
      next true if token.user.can_read_all_resources?

      boundary.member?(token.user)
    end

    condition(:visible, score: 0) do
      boundary.visible_to?(token.user)
    end

    rule { member | visible }.enable :read_boundary

    ::Authz::PermissionGroups::Assignable.all_permissions.each do |permission|
      desc "Token permission that enables #{permission} for boundary"
      condition(permission) do
        token.permitted_for_boundary?(boundary, permission)
      end

      desc "Anonymous caller would be granted #{permission} on the boundary's resource"
      condition(:"anonymous_can_#{permission}") do
        resource = boundary.boundary
        next false unless resource.is_a?(::Project) || resource.is_a?(::Group)

        ::Users::Anonymous.can?(permission, resource) # rubocop:disable Gitlab/Authz/DisallowAbilityAllowed -- querying anonymous access, not the token
      end

      rule { granular_pat & cond(:"anonymous_can_#{permission}") }.enable permission
      rule { granular_pat & cond(permission) & member }.enable permission
    end
  end
end
