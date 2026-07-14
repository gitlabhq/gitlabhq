# frozen_string_literal: true

module DependencyProxy
  # Shared granular (fine-grained) token check for a dependency proxy pull.
  # Used both when minting the JWT (Auth::ContainerProxyAuthenticationService)
  # and when consuming it (DependencyProxy::GroupAccess).
  module GranularAuthorization
    extend self

    def pull_authorized?(token, group)
      ::Authz::Tokens::AuthorizeGranularScopesService.new(
        boundaries: ::Authz::Boundary.for(group),
        permissions: :read_dependency_proxy,
        token: token
      ).execute.success?
    end
  end
end
