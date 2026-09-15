# frozen_string_literal: true

Gitlab::Application.config.to_prepare do
  Search::ScopeHandlers::Registry.register(:groups, Search::ScopeHandlers::Groups)
end
