# frozen_string_literal: true

module Authz
  class BoundaryPolicy < ::BasePolicy
    alias_method :token, :user
    alias_method :boundary, :subject

    condition(:granular_pat) do
      token.is_a?(::PersonalAccessToken) && token.granular?
    end

    ::Authz::Permission.all.each_key do |permission|
      desc "Token permission that enables #{permission} for boundary"
      condition(permission) do
        token.permitted_for_boundary?(boundary, permission)
      end

      condition(:member) do
        boundary.member?(token.user)
      end

      rule { granular_pat & try(permission) & member }.policy do
        enable permission
      end
    end
  end
end
