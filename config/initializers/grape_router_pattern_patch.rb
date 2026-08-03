# frozen_string_literal: true

# Grape (via mustermann-grape; ruby-grape/grape#2379) feeds declared parameter
# *types* into route matching: a `type: Integer` path parameter compiles to a
# digits-only route segment. A request whose segment is not all digits (a signed
# integer such as `-1`, or a non-numeric value such as `abc`) then fails to match
# the route, and Grape returns a generic `{"error":"404 Not Found"}` before
# parameter validation or the endpoint runs.
#
# Hundreds of GitLab endpoints declare `type: Integer` path parameters and rely on
# the request reaching validation (`400 ... is invalid` for malformed values) and
# the endpoint (its own `not_found!` message for valid-but-missing records).
# Changing those responses would be a breaking REST API change.
#
# This patch keeps that contract by not forwarding declared param types to
# Mustermann when the route pattern is built. Parameter validation is unaffected
# (the value is still coerced and validated after routing), so only route matching
# changes.
#
# Behaviour is pinned by spec/initializers/grape_router_pattern_patch_spec.rb.
module GrapeRouterPatternPatch
  private

  # Pinned to the positional signature of Grape::Router::Pattern's private
  # #build_pattern. A Grape upgrade that changes its arity raises here; one that
  # renames or removes it is caught by the spec above.
  def build_pattern(path, _params, format, version, requirements)
    super(path, {}, format, version, requirements)
  end
end

Grape::Router::Pattern.prepend(GrapeRouterPatternPatch)
